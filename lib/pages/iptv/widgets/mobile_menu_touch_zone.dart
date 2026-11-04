import 'package:flutter/material.dart';

/// Phone-only left-edge target for opening the channel menu.
///
/// The entire left-side region is tappable, while the small edge tab makes the
/// gesture discoverable without covering playback with a floating button.
class MobileMenuTouchZone extends StatelessWidget {
  final VoidCallback onTap;

  const MobileMenuTouchZone({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = (screenWidth * 0.2).clamp(96.0, 160.0).toDouble();

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: width,
      child: Semantics(
        button: true,
        label: '打开频道菜单',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.black.withOpacity(0.48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: const SizedBox(
                width: 46,
                height: 78,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_open_rounded,
                        color: Colors.white, size: 21),
                    SizedBox(height: 4),
                    Text(
                      '菜单',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
