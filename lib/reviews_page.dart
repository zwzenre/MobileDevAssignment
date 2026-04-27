import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const ReviewsPage({super.key, required this.restaurant});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Simplified query - just get reviews without users join
      final response = await supabase
          .from('reviews')
          .select()
          .eq('resid', widget.restaurant['resid'] ?? widget.restaurant['id'])
          .order('created_at', ascending: false);

      print('Fetched ${response.length} reviews'); // Debug print

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addReview(String comment, double rating) async {
    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to write a review')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Insert review
      await supabase.from('reviews').insert({
        'resid': widget.restaurant['resid'] ?? widget.restaurant['id'],
        'userid': user.id,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Refresh the list
      await _fetchReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error adding review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReview(String revid) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('reviews').delete().eq('revid', revid);
      await _fetchReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showReviewDialog() async {
    final commentController = TextEditingController();
    double selectedRating = 5.0;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Write a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rating Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            selectedRating = (index + 1).toDouble();
                          });
                        },
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Comment Field
                  TextField(
                    controller: commentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please write a comment')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await _addReview(commentController.text.trim(), selectedRating);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    double total = _reviews.fold(0, (sum, review) => sum + (review['rating'] as num).toDouble());
    return total / _reviews.length;
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return 'Recently';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (user != null)
            IconButton(
              onPressed: _showReviewDialog,
              icon: const Icon(Icons.add),
              tooltip: 'Write a review',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (user != null)
              ElevatedButton.icon(
                onPressed: _showReviewDialog,
                icon: const Icon(Icons.add),
                label: const Text('Write a Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
          ],
        ),
      )
          : Column(
        children: [
          // Average Rating Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Average Rating',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        _buildRatingStars(averageRating),
                        const SizedBox(height: 4),
                        Text(
                          '${_reviews.length} review${_reviews.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reviews List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final isOwnReview = user?.id == review['userid'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info & Rating
                        Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              backgroundColor: Colors.orange[100],
                              child: const Icon(Icons.person, color: Colors.orange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'User ${review['userid']?.toString().substring(0, 6) ?? 'Anonymous'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRatingStars(review['rating'].toDouble()),
                                ],
                              ),
                            ),
                            if (isOwnReview)
                              IconButton(
                                onPressed: () => _deleteReview(review['revid']),
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                tooltip: 'Delete review',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Comment
                        Text(
                          review['comment'] ?? '',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        // Date
                        Text(
                          _formatDate(review['created_at']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}