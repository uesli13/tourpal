import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MyToursScreen extends StatefulWidget {
  const MyToursScreen({super.key});

  @override
  State<MyToursScreen> createState() => _MyToursScreenState();
}

class _MyToursScreenState extends State<MyToursScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Tours',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showCreateTourDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tour analytics coming soon!')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active Tours'),
            Tab(text: 'Draft Tours'),
            Tab(text: 'Past Tours'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTours(),
          _buildDraftTours(),
          _buildPastTours(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateTourDialog(context);
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Create Tour'),
      ),
    );
  }

  Widget _buildActiveTours() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTourCard(
          title: 'Historic Downtown Walking Tour',
          description: 'Explore the rich history of our beautiful downtown area',
          price: 25.0,
          duration: '2 hours',
          bookings: 8,
          status: 'Active',
          statusColor: Colors.green,
          imageUrl: null,
        ),
        const SizedBox(height: 16),
        _buildTourCard(
          title: 'Sunset Photography Workshop',
          description: 'Learn photography techniques during golden hour',
          price: 45.0,
          duration: '3 hours',
          bookings: 12,
          status: 'Active',
          statusColor: Colors.green,
          imageUrl: null,
        ),
        const SizedBox(height: 16),
        _buildEmptyState(
          icon: Icons.tour,
          title: 'Ready to Create More Tours?',
          subtitle: 'Share your expertise with travelers around the world',
          buttonText: 'Create New Tour',
        ),
      ],
    );
  }

  Widget _buildDraftTours() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTourCard(
          title: 'Food Market Discovery Tour',
          description: 'Taste local flavors and meet passionate vendors',
          price: 35.0,
          duration: '2.5 hours',
          bookings: 0,
          status: 'Draft',
          statusColor: Colors.orange,
          imageUrl: null,
        ),
        const SizedBox(height: 16),
        _buildEmptyState(
          icon: Icons.edit,
          title: 'Finish Your Draft Tours',
          subtitle: 'Complete your tour details to start accepting bookings',
          buttonText: 'Continue Editing',
        ),
      ],
    );
  }

  Widget _buildPastTours() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTourCard(
          title: 'Art Gallery Walking Tour',
          description: 'Discover local artists and their incredible works',
          price: 30.0,
          duration: '2 hours',
          bookings: 24,
          status: 'Completed',
          statusColor: Colors.grey,
          imageUrl: null,
        ),
        const SizedBox(height: 16),
        _buildEmptyState(
          icon: Icons.history,
          title: 'Your Tour History',
          subtitle: 'View insights and feedback from your past tours',
          buttonText: 'View Analytics',
        ),
      ],
    );
  }

  Widget _buildTourCard({
    required String title,
    required String description,
    required double price,
    required String duration,
    required int bookings,
    required String status,
    required Color statusColor,
    String? imageUrl,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tour Image
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.7), Colors.orange.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.tour,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          
          // Tour Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    Text(
                      '\$${price.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    Text(
                      duration,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Icon(Icons.group, size: 16, color: Colors.grey[600]),
                    Text(
                      '$bookings bookings',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit tour coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View details coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showCreateTourDialog(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(buttonText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateTourDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Tour'),
        content: const Text('The tour creation feature is coming soon! You\'ll be able to create detailed tour experiences with photos, itineraries, and pricing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('We\'ll notify you when this feature is ready!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Notify Me', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}