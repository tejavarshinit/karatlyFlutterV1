class Product {
  final String id;
  final String sku;
  final String name;
  final String description;
  final String basePrice;
  final String metalType;
  final String purity;
  final String productWeight;
  final String redeemWeight;
  final String jewelleryType;
  final String productSize;
  final String status;
  final dynamic stockQuantity;
  final List<ProductImage> productImages;
  final String imageUrl;

  const Product({
    this.id = '',
    this.sku = '',
    this.name = 'Untitled Product',
    this.description = '',
    this.basePrice = '0',
    this.metalType = 'NA',
    this.purity = 'NA',
    this.productWeight = 'NA',
    this.redeemWeight = 'NA',
    this.jewelleryType = 'NA',
    this.productSize = 'NA',
    this.status = 'inactive',
    this.stockQuantity,
    this.productImages = const [],
    this.imageUrl = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = (json['productImages'] as List<dynamic>?)
            ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return Product(
      id: json['sku']?.toString() ?? 'product-${DateTime.now().millisecondsSinceEpoch}',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Product',
      description: (json['description']?.toString() ?? '') != 'NA' ? json['description']?.toString() ?? '' : '',
      basePrice: json['basePrice']?.toString() ?? '0',
      metalType: json['metalType']?.toString() ?? 'NA',
      purity: json['purity']?.toString() ?? 'NA',
      productWeight: json['productWeight']?.toString() ?? 'NA',
      redeemWeight: json['redeemWeight']?.toString() ?? 'NA',
      jewelleryType: json['jewelleryType']?.toString() ?? 'NA',
      productSize: json['productSize']?.toString() ?? 'NA',
      status: json['status']?.toString() ?? 'inactive',
      stockQuantity: json['stockQuantity'] ?? json['stock_quantity'] ?? json['availableQuantity'],
      productImages: images,
      imageUrl: _selectProductImage(images),
    );
  }

  static String _selectProductImage(List<ProductImage> images) {
    if (images.isEmpty) return '';
    final defaultImage = images.where((i) => i.defaultImage && i.url.isNotEmpty).firstOrNull;
    if (defaultImage != null) return defaultImage.url;
    final ordered = images.where((i) => i.url.isNotEmpty).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return ordered.isNotEmpty ? ordered.first.url : '';
  }
}

class ProductImage {
  final String url;
  final bool defaultImage;
  final int displayOrder;

  const ProductImage({
    this.url = '',
    this.defaultImage = false,
    this.displayOrder = 0,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url']?.toString() ?? '',
      defaultImage: json['defaultImage'] == true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}

class Pagination {
  final bool hasMore;
  final int count;
  final int perPage;
  final int currentPage;

  const Pagination({
    this.hasMore = false,
    this.count = 0,
    this.perPage = 0,
    this.currentPage = 1,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      hasMore: json['hasMore'] == true,
      count: json['count'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
    );
  }
}

class CartItem {
  final String id;
  final String name;
  final double weight;
  final double price;
  final String thumbnail;

  const CartItem({
    required this.id,
    required this.name,
    required this.weight,
    required this.price,
    this.thumbnail = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weight': weight,
    'price': price,
    'thumbnail': thumbnail,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      weight: double.tryParse(json['weight'].toString()) ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0,
      thumbnail: json['thumbnail']?.toString() ?? '',
    );
  }
}
