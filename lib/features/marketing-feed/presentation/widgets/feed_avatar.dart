import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/network/auth_token_cache.dart';
import 'package:progress_group/core/utils/helpers/initial_name_helper.dart';

const _avatarPalette = [
  purpleColor,
  orangeAccentColor,
  secondaryColor,
  greenMaterialColor,
  redAccentColor,
  infoColor,
  feedPinkColor,
];

/// Avatar foto kalau ada, selain itu inisial di atas warna yang selalu sama untuk nama yang sama.
/// [radius] null = bulat penuh.
class FeedAvatar extends StatelessWidget {
  final String name;
  final String? initials;
  final String? photoUrl;
  final bool isModerator;
  final double size;
  final double? radius;

  const FeedAvatar({
    super.key,
    required this.name,
    this.initials,
    this.photoUrl,
    this.isModerator = false,
    this.size = 38,
    this.radius,
  });

  Color get _color {
    if (isModerator) return const Color(primaryColor);
    final seed = name.codeUnits.fold(0, (sum, c) => sum + c);
    return Color(_avatarPalette[seed % _avatarPalette.length]);
  }

  BorderRadius get _borderRadius => BorderRadius.circular(radius ?? size / 2);

  @override
  Widget build(BuildContext context) {
    final displayText = (initials != null && initials!.isNotEmpty)
        ? initials!
        : getInitials(name);

    final initialsWidget = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _color, borderRadius: _borderRadius),
      child: Text(
        displayText,
        style: TextStyle(
          color: const Color(whiteColor),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );

    final url = photoUrl;
    if (url == null || url.isEmpty) return initialsWidget;

    return ClipRRect(
      borderRadius: _borderRadius,
      child: Image.network(
        url,
        headers: AuthTokenCache.getAuthHeadersFor(url),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initialsWidget,
      ),
    );
  }
}
