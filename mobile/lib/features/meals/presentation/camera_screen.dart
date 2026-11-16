import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/quotas_controller.dart';
import 'package:omeo_api/omeo_api.dart' show Quota, QuotaFeatureEnum;
import 'package:permission_handler/permission_handler.dart';

/// Destinations du viseur, fournies par le routeur.
typedef CameraNavigation = ({
  ValueChanged<Uint8List> onPhoto,
  VoidCallback onClose,
  VoidCallback? onVoice,
});

/// Choisit une photo dans la galerie (réelle, jamais simulée). `null` si
/// l'utilisateur renonce.
Future<Uint8List?> pickMealPhotoFromGallery() async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery);
  return file?.readAsBytes();
}

/// Viseur photo plein écran (MEA-02) : caméra réelle, cadre de visée,
/// conseil de cadrage, flash, galerie et quota restant. Permission refusée :
/// écran dédié (SYS-06).
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({required this.navigation, super.key});

  final CameraNavigation navigation;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

enum _CameraStatus { starting, ready, denied, unavailable }

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  _CameraStatus _status = _CameraStatus.starting;
  bool _flash = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  // La caméra est libérée en arrière-plan et rouverte au retour (après un
  // passage dans les réglages, par exemple).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controller = _controller;
      _controller = null;
      unawaited(controller?.dispose());
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (cameras.isEmpty) {
        _setStatus(_CameraStatus.unavailable);
        return;
      }
      final controller = CameraController(
        back.isEmpty ? cameras.first : back.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _flash = false;
      _setStatus(_CameraStatus.ready);
    } on CameraException catch (e) {
      _setStatus(
        e.code.startsWith('CameraAccess')
            ? _CameraStatus.denied
            : _CameraStatus.unavailable,
      );
    }
  }

  void _setStatus(_CameraStatus status) {
    if (mounted) setState(() => _status = status);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = !_flash;
    await controller.setFlashMode(next ? FlashMode.always : FlashMode.off);
    if (mounted) setState(() => _flash = next);
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      unawaited(HapticFeedback.mediumImpact());
      final file = await controller.takePicture();
      widget.navigation.onPhoto(await file.readAsBytes());
    } on CameraException {
      _setStatus(_CameraStatus.unavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gallery() async {
    final bytes = await pickMealPhotoFromGallery();
    if (bytes != null) widget.navigation.onPhoto(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      _CameraStatus.denied => CameraDeniedView(
        onClose: widget.navigation.onClose,
        onOpenSettings: () => unawaited(openAppSettings()),
        onPickFromGallery: () => unawaited(_gallery()),
      ),
      _ => _Viewfinder(
        controller: _status == _CameraStatus.ready ? _controller : null,
        unavailable: _status == _CameraStatus.unavailable,
        flash: _flash,
        busy: _busy,
        onClose: widget.navigation.onClose,
        onFlash: () => unawaited(_toggleFlash()),
        onShoot: () => unawaited(_shoot()),
        onGallery: () => unawaited(_gallery()),
        onVoice: widget.navigation.onVoice,
      ),
    };
  }
}

class _Viewfinder extends ConsumerWidget {
  const _Viewfinder({
    required this.controller,
    required this.unavailable,
    required this.flash,
    required this.busy,
    required this.onClose,
    required this.onFlash,
    required this.onShoot,
    required this.onGallery,
    required this.onVoice,
  });

  final CameraController? controller;
  final bool unavailable;
  final bool flash;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onFlash;
  final VoidCallback onShoot;
  final VoidCallback onGallery;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final quotas = ref.watch(quotasProvider).value;
    final photo = quotas == null
        ? null
        : quotaFor(quotas, QuotaFeatureEnum.photoAnalysis);
    final camera = controller;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (camera != null)
              Semantics(
                label: l.appMealCameraPreview,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: camera.value.previewSize?.height ?? 1,
                    height: camera.value.previewSize?.width ?? 1,
                    child: CameraPreview(camera),
                  ),
                ),
              )
            else if (unavailable)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l.appMealCameraUnavailable,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              )
            else
              const Center(child: OmeoSpinner()),
            const _Shade(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _RoundButton(
                          icon: OmeoIcons.x,
                          label: l.appMealCameraClose,
                          onTap: onClose,
                        ),
                        const Spacer(),
                        if (photo != null) _QuotaTag(quota: photo),
                        const Spacer(),
                        _RoundButton(
                          icon: OmeoIcons.bolt,
                          label: flash
                              ? l.appMealCameraFlashOff
                              : l.appMealCameraFlashOn,
                          selected: flash,
                          onTap: camera == null ? null : onFlash,
                        ),
                      ],
                    ),
                    const Expanded(child: _Frame()),
                    Text(
                      l.appMealCameraTip,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _RoundButton(
                          icon: OmeoIcons.image,
                          label: l.appMealCameraGallery,
                          square: true,
                          onTap: onGallery,
                        ),
                        _Shutter(
                          label: l.appMealCameraShutter,
                          busy: busy,
                          onTap: camera == null ? null : onShoot,
                        ),
                        _RoundButton(
                          icon: OmeoIcons.mic,
                          label: l.appMealCameraVoice,
                          square: true,
                          onTap: onVoice,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dégradé haut et bas pour la lisibilité des commandes.
class _Shade extends StatelessWidget {
  const _Shade();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.25, 0.65, 1],
          colors: [
            Color(0x73000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0xB3000000),
          ],
        ),
      ),
    ),
  );
}

/// Cadre de visée : quatre coins arrondis.
class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: CustomPaint(painter: _FramePainter(), child: SizedBox.expand()),
    ),
  );
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 46.0;
    const r = 22.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    final corners = [
      Path()
        ..moveTo(0, arm)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(arm, 0),
      Path()
        ..moveTo(w - arm, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, arm),
      Path()
        ..moveTo(0, h - arm)
        ..lineTo(0, h - r)
        ..arcToPoint(
          Offset(r, h),
          radius: const Radius.circular(r),
          clockwise: false,
        )
        ..lineTo(arm, h),
      Path()
        ..moveTo(w - arm, h)
        ..lineTo(w - r, h)
        ..arcToPoint(
          Offset(w, h - r),
          radius: const Radius.circular(r),
          clockwise: false,
        )
        ..lineTo(w, h - arm),
    ];
    for (final c in corners) {
      canvas.drawPath(c, paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}

class _QuotaTag extends StatelessWidget {
  const _QuotaTag({required this.quota});

  final Quota quota;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final remaining = quota.remaining;
    return Flexible(
      child: OmeoTag(
        remaining == null
            ? l.appMealAddUnlimited
            : l.appMealAnalysesLeft(remaining),
        tone: OmeoTone.glass,
        icon: OmeoIcons.camera,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.square = false,
    this.selected = false,
  });

  final OmeoIcons icon;
  final String label;
  final VoidCallback? onTap;
  final bool square;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final side = square ? 52.0 : 44.0;
    return Semantics(
      button: true,
      toggled: selected ? true : null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: square ? 0 : 0.35),
        borderRadius: BorderRadius.circular(square ? 16 : side),
        child: InkWell(
          borderRadius: BorderRadius.circular(square ? 16 : side),
          onTap: onTap,
          child: Ink(
            width: side,
            height: side,
            decoration: square
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Center(child: OmeoIcon(icon, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null && !busy,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: OmeoTokens.durationFast,
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 5),
          color: Colors.white.withValues(alpha: busy ? 0.6 : 0.25),
        ),
      ),
    ),
  );
}

/// Caméra refusée (SYS-06) : explication, réglages, et la galerie comme
/// alternative sans caméra.
class CameraDeniedView extends StatelessWidget {
  const CameraDeniedView({
    required this.onClose,
    required this.onOpenSettings,
    required this.onPickFromGallery,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onOpenSettings;
  final VoidCallback onPickFromGallery;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: '',
              backLabel: l.commonActionClose,
              close: true,
              onBack: onClose,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 72, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: t.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: OmeoIcon(
                          OmeoIcons.camera,
                          size: 40,
                          color: t.text2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        l.appMealCameraDeniedTitle,
                        textAlign: TextAlign.center,
                        style: text.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: OmeoTokens.space2),
                    Text(
                      l.appMealCameraDeniedBody,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: t.text2),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  OmeoButton(
                    label: l.appMealCameraOpenSettings,
                    onPressed: onOpenSettings,
                  ),
                  const SizedBox(height: OmeoTokens.space1),
                  OmeoButton(
                    label: l.appMealCameraPickGallery,
                    variant: OmeoButtonVariant.ghost,
                    onPressed: onPickFromGallery,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
