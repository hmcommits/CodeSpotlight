class IconUtil {
  static String getSimpleIconSlug(String techName) {
    String slug = techName.toLowerCase().trim();
    
    // Explicit overrides for common variations
    final overrides = {
      'aws': 'amazonwebservices',
      'gcp': 'googlecloud',
      'react native': 'react',
      'react js': 'react',
      'reactjs': 'react',
      'node': 'nodedotjs',
      'vue': 'vuedotjs',
      'golang': 'go',
      'js': 'javascript',
      'ts': 'typescript',
      'html': 'html5',
      'css': 'css3',
      'postgres': 'postgresql',
      'k8s': 'kubernetes',
      'c#': 'csharp',
      'f#': 'fsharp',
      'c++': 'cplusplus',
    };
    
    if (overrides.containsKey(slug)) {
      return overrides[slug]!;
    }

    // General substitutions
    slug = slug.replaceAll(' ', '');
    slug = slug.replaceAll('+', 'plus');
    slug = slug.replaceAll('#', 'sharp');
    slug = slug.replaceAll('.', 'dot');

    return slug;
  }
}
