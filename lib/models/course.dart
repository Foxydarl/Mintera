class Course {
  final String id;
  final String title;
  final String description;
  final String author;
  final int price;
  final String imageUrl;
  final int views;
  final int likes;
  final double rating;
  final String category;
  final String? owner;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.price,
    required this.imageUrl,
    required this.views,
    required this.likes,
    required this.rating,
    required this.category,
    this.owner,
  });

  factory Course.fromMap(Map<String, dynamic> map) => Course(
        id: map['id'].toString(),
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        author: map['author'] ?? '',
        price: (map['price'] ?? 0) as int,
        imageUrl: map['image_url'] ?? '',
        views: (map['views'] ?? 0) as int,
        likes: (map['likes'] ?? 0) as int,
        rating: (map['rating'] ?? 0).toDouble(),
        category: map['category'] ?? 'Общее',
        owner: map['owner']?.toString(),
      );
}
