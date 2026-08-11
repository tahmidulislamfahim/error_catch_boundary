import 'package:flutter/material.dart';
import 'package:error_catch_boundary/error_catch_boundary.dart';

void main() {
  runApp(const ErrorBoundaryExampleApp());
}

class ErrorBoundaryExampleApp extends StatelessWidget {
  const ErrorBoundaryExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalErrorBoundaryConfig(
      showDebugDetails: true,
      onError: (details) {
        debugPrint('[GlobalErrorBoundaryConfig Logger] Caught: ${details.error}');
      },
      child: MaterialApp(
        title: 'Flutter Error Boundary Demo v1.1.0',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        home: const DemoHomeScreen(),
      ),
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  bool _simulateCard2Error = false;
  bool _simulateAutoRetryError = false;
  bool _simulateIgnoredError = false;

  final ErrorBoundaryController _globalController = ErrorBoundaryController();
  final List<String> _logs = [];

  void _logError(FlutterErrorBoundaryDetails details) {
    setState(() {
      _logs.insert(0,
          '[${DateTime.now().toString().split('.').first}] Intercepted: ${details.error}');
    });
  }

  @override
  void dispose() {
    _globalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Boundary v1.1.0 Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset All Boundaries (Controller)',
            onPressed: () {
              _globalController.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Triggered reset via ErrorBoundaryController!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulation Controls',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Simulate Error in Card #2'),
                      subtitle: const Text(
                          'Catches error and displays DefaultErrorFallback with expandable Debug Details'),
                      value: _simulateCard2Error,
                      onChanged: (val) =>
                          setState(() => _simulateCard2Error = val),
                    ),
                    SwitchListTile(
                      title: const Text('Simulate Auto-Retry Card Error'),
                      subtitle: const Text(
                          'Uses AutoRetryConfig (max 3 retries, 2s interval)'),
                      value: _simulateAutoRetryError,
                      onChanged: (val) =>
                          setState(() => _simulateAutoRetryError = val),
                    ),
                    SwitchListTile(
                      title: const Text('Simulate Bypassed Error (shouldCatch)'),
                      subtitle: const Text(
                          'Filter predicate returns false for FormatException, allowing standard Flutter erroring'),
                      value: _simulateIgnoredError,
                      onChanged: (val) =>
                          setState(() => _simulateIgnoredError = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Dashboard Cards (Isolated Boundaries):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Dashboard Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Card 1: Standard
                SizedBox(
                  width: 340,
                  child: ErrorBoundary(
                    controller: _globalController,
                    onError: _logError,
                    child: const DemoCardContent(
                      id: 1,
                      title: 'Analytics Overview',
                      icon: Icons.analytics_outlined,
                      color: Color(0xFFE3F2FD),
                      shouldThrow: false,
                    ),
                  ),
                ),

                // Card 2: Interactive with Controller & Debug Inspector
                SizedBox(
                  width: 340,
                  child: ErrorBoundary(
                    controller: _globalController,
                    onError: _logError,
                    child: DemoCardContent(
                      id: 2,
                      title: 'Live Transactions',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFFFFF8E1),
                      shouldThrow: _simulateCard2Error,
                    ),
                  ),
                ),

                // Card 3: Auto-Retry Config
                SizedBox(
                  width: 340,
                  child: ErrorBoundary(
                    controller: _globalController,
                    onError: _logError,
                    autoRetryConfig: const AutoRetryConfig(
                      maxRetries: 3,
                      retryInterval: Duration(seconds: 2),
                    ),
                    child: DemoCardContent(
                      id: 3,
                      title: 'Auto-Healing Component',
                      icon: Icons.autorenew,
                      color: const Color(0xFFE8F5E9),
                      shouldThrow: _simulateAutoRetryError,
                    ),
                  ),
                ),

                // Card 4: Filtered error
                SizedBox(
                  width: 340,
                  child: ErrorBoundary(
                    controller: _globalController,
                    onError: _logError,
                    shouldCatch: (details) {
                      // Filter out FormatException
                      return details.error is! FormatException;
                    },
                    child: DemoCardContent(
                      id: 4,
                      title: 'Filtered Predicate Card',
                      icon: Icons.filter_alt_outlined,
                      color: const Color(0xFFF3E5F5),
                      shouldThrow: _simulateIgnoredError,
                      customException:
                          const FormatException('Bypassed FormatException!'),
                    ),
                  ),
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
              height: 160,
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
}

class DemoCardContent extends StatelessWidget {
  final int id;
  final String title;
  final IconData icon;
  final Color color;
  final bool shouldThrow;
  final Object? customException;

  const DemoCardContent({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.shouldThrow,
    this.customException,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldThrow) {
      throw customException ??
          Exception('Uncaught render failure in Item #$id ($title)');
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
