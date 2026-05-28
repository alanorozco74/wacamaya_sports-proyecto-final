import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constants.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageName;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CustomNetworkImage({
    super.key,
    required this.imageName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Detecta si es una URL completa o si necesita la base de GitHub
    final String fullUrl = imageName.startsWith('http')
        ? imageName
        : '${ApiConstants.githubImageBaseUrl}$imageName';

    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }
}
