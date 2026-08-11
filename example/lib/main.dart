import 'package:flutter/material.dart';
import 'package:error_catch_boundary/error_catch_boundary.dart';

void main() {
  runApp(const ErrorBoundaryExampleApp());
}

class ErrorBoundaryExampleApp extends StatelessWidget {
  const ErrorBoundaryExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Error Boundary Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const DemoHomeScreen(),
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  bool _simulateCardError = false;
  final List<String> _logs = [];

  void _logError(FlutterErrorBoundaryDetails details) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().split('.').first}] Intercepted error: ${details.error}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Boundary Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Clear Logs',
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text(
                  'Simulate UI Build Failure',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Toggles item #2 to throw an unhandled exception inside build()'),
                value: _simulateCardError,
                onChanged: (val) {
                  setState(() {
                    _simulateCardError = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Dashboard Items (Isolated Error Boundaries):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Dashboard Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDemoItem(
                  id: 1,
                  title: 'Analytics Overview',
                  icon: Icons.analytics_outlined,
                  color: Colors.blue.shade100,
                  shouldThrow: false,
                ),
                _buildDemoItem(
                  id: 2,
                  title: 'Live Transactions',
                  icon: Icons.receipt_long_outlined,
                  color: Colors.amber.shade100,
                  shouldThrow: _simulateCardError,
                ),
                _buildDemoItem(
                  id: 3,
                  title: 'User Profile & Settings',
                  icon: Icons.person_outline,
                  color: Colors.green.shade100,
                  shouldThrow: false,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Intercepted Logger Stream:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Log Console
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No errors intercepted yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoItem({
    required int id,
    required String title,
    required IconData icon,
    required Color color,
    required bool shouldThrow,
  }) {
    return SizedBox(
      width: 320,
      child: ErrorBoundary(
        onError: _logError,
        child: DemoCardContent(
          id: id,
          title: title,
          icon: icon,
          color: color,
          shouldThrow: shouldThrow,
        ),
      ),
    );
  }
}

class DemoCardContent extends StatelessWidget {
  final int id;
  final String title;
  final IconData icon;
  final Color color;
  final bool shouldThrow;

  const DemoCardContent({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.shouldThrow,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldThrow) {
      throw Exception('Uncaught render failure in Item #$id ($title)');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 8),
              Text(
                'Item #$id',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          const Text(
            'Status: Operating normally',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
