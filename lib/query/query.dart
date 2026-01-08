import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Mock data model for queries
class CustomerQuery {
  final int id;
  final String customerName;
  final String querySubject;
  final String queryPreview;
  final DateTime timestamp;
  QueryStatus status;
  final bool isPriority;
  List<QueryResponse> responses;

  CustomerQuery({
    required this.id,
    required this.customerName,
    required this.querySubject,
    required this.queryPreview,
    required this.timestamp,
    required this.status,
    this.isPriority = false,
    this.responses = const [],
  });
}

// Model for query responses/answers
class QueryResponse {
  final String responseText;
  final DateTime timestamp;
  final String responderName;

  QueryResponse({
    required this.responseText,
    required this.timestamp,
    required this.responderName,
  });
}

enum QueryStatus { pending, inProgress, resolved, closed }

class QueryPage extends StatefulWidget {
  @override
  _QueryPageState createState() => _QueryPageState();
}

class _QueryPageState extends State<QueryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  QueryStatus? _filterStatus;

  // Mock data
  final List<CustomerQuery> _queries = [
    CustomerQuery(
      id: 1001,
      customerName: "Sarah Johnson",
      querySubject: "Billing Issue",
      queryPreview: "I was charged twice for my last appointment...",
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      status: QueryStatus.pending,
      isPriority: true,
      responses: [],
    ),
    CustomerQuery(
      id: 1002,
      customerName: "Michael Chen",
      querySubject: "Appointment Reschedule",
      queryPreview: "Need to reschedule my appointment on Friday...",
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      status: QueryStatus.inProgress,
      responses: [
        QueryResponse(
          responseText: "Hi Michael, I've checked our calendar and we have openings on Monday at 10am or Wednesday at 2pm. Would either of those work for you?",
          timestamp: DateTime.now().subtract(Duration(hours: 3)),
          responderName: "Staff",
        ),
      ],
    ),
    CustomerQuery(
      id: 1003,
      customerName: "Emily Rodriguez",
      querySubject: "Prescription Refill",
      queryPreview: "Requesting a refill for my medication...",
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      status: QueryStatus.resolved,
      responses: [
        QueryResponse(
          responseText: "Hello Emily, I've submitted your refill request to the pharmacy. It should be ready for pickup tomorrow.",
          timestamp: DateTime.now().subtract(Duration(hours: 12)),
          responderName: "Dr. Smith",
        ),
      ],
    ),
    CustomerQuery(
      id: 1004,
      customerName: "James Wilson",
      querySubject: "Medical Records Request",
      queryPreview: "I need a copy of my medical records from...",
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      status: QueryStatus.pending,
      responses: [],
    ),
    CustomerQuery(
      id: 1005,
      customerName: "Aisha Patel",
      querySubject: "Insurance Coverage",
      queryPreview: "Question about coverage for upcoming procedure...",
      timestamp: DateTime.now().subtract(Duration(days: 3)),
      status: QueryStatus.closed,
      responses: [
        QueryResponse(
          responseText: "Hi Aisha, I've verified with your insurance provider that the procedure is covered at 80%. Your estimated out-of-pocket cost will be approximately 250.",
          timestamp: DateTime.now().subtract(Duration(days: 2)),
          responderName: "Admin",
        ),
        QueryResponse(
          responseText: "Thank you for the information. I'll proceed with scheduling the procedure.",
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          responderName: "Aisha Patel",
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CustomerQuery> get _filteredQueries {
    return _queries.where((query) {
      // Apply status filter if selected
      if (_tabController.index > 0) {
        QueryStatus statusFilter = QueryStatus.values[_tabController.index - 1];
        if (query.status != statusFilter) return false;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        return query.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            query.querySubject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            query.id.toString().contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  Color _getStatusColor(QueryStatus status) {
    switch (status) {
      case QueryStatus.pending: return Colors.orange;
      case QueryStatus.inProgress: return Colors.blue;
      case QueryStatus.resolved: return Colors.green;
      case QueryStatus.closed: return Colors.grey;
    }
  }

  String _getStatusText(QueryStatus status) {
    switch (status) {
      case QueryStatus.pending: return 'Pending';
      case QueryStatus.inProgress: return 'In Progress';
      case QueryStatus.resolved: return 'Resolved';
      case QueryStatus.closed: return 'Closed';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Queries'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Refresh queries (would fetch from API in real app)
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              _showFilterDialog();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {});
          },
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by ID, customer, or subject...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _filteredQueries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No queries found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: _filteredQueries.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final query = _filteredQueries[index];
                return _buildQueryCard(query);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Showing ${_filteredQueries.length} of ${_queries.length} queries',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text('New Query'),
        onPressed: () {
          // Navigate to create query screen
        },
      ),
    );
  }

  Widget _buildQueryCard(CustomerQuery query) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: query.isPriority
            ? BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QueryDetailPage(
                query: query,
                onStatusChange: (newStatus) {
                  setState(() {
                    query.status = newStatus;
                  });
                },
                onResponseAdded: (response) {
                  setState(() {
                    query.responses.add(response);
                    if (query.status == QueryStatus.pending) {
                      query.status = QueryStatus.inProgress;
                    }
                  });
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(query.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(query.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusColor(query.status),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          _getStatusText(query.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(query.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  if (query.isPriority)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.priority_high, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            'Priority',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Spacer(),
                  Text(
                    '#${query.id}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                query.querySubject,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                query.queryPreview,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey[100],
                    radius: 16,
                    child: Text(
                      query.customerName.split(' ').map((e) => e[0]).join('').toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    query.customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(query.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (query.responses.isNotEmpty) ...[
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.question_answer_outlined, size: 16, color: Colors.blue[700]),
                    SizedBox(width: 4),
                    Text(
                      '${query.responses.length} ${query.responses.length == 1 ? 'response' : 'responses'}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Last updated: ${_formatDate(query.responses.last.timestamp)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter Queries'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('All Queries'),
                leading: Radio<QueryStatus?>(
                  value: null,
                  groupValue: _filterStatus,
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value;
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
              ...QueryStatus.values.map(
                    (status) => ListTile(
                  title: Text(_getStatusText(status)),
                  leading: Radio<QueryStatus?>(
                    value: status,
                    groupValue: _filterStatus,
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value;
                        Navigator.pop(context);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// New page for query details and responses
class QueryDetailPage extends StatefulWidget {
  final CustomerQuery query;
  final Function(QueryStatus) onStatusChange;
  final Function(QueryResponse) onResponseAdded;

  const QueryDetailPage({
    Key? key,
    required this.query,
    required this.onStatusChange,
    required this.onResponseAdded,
  }) : super(key: key);

  @override
  _QueryDetailPageState createState() => _QueryDetailPageState();
}

class _QueryDetailPageState extends State<QueryDetailPage> {
  final TextEditingController _responseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _responseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Color _getStatusColor(QueryStatus status) {
    switch (status) {
      case QueryStatus.pending: return Colors.orange;
      case QueryStatus.inProgress: return Colors.blue;
      case QueryStatus.resolved: return Colors.green;
      case QueryStatus.closed: return Colors.grey;
    }
  }

  String _getStatusText(QueryStatus status) {
    switch (status) {
      case QueryStatus.pending: return 'Pending';
      case QueryStatus.inProgress: return 'In Progress';
      case QueryStatus.resolved: return 'Resolved';
      case QueryStatus.closed: return 'Closed';
    }
  }

  void _submitResponse() {
    if (_responseController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(Duration(milliseconds: 500), () {
      final newResponse = QueryResponse(
        responseText: _responseController.text.trim(),
        timestamp: DateTime.now(),
        responderName: "Staff", // In a real app, use the logged-in user's name
      );

      widget.onResponseAdded(newResponse);

      setState(() {
        _responseController.clear();
        _isLoading = false;
      });

      // Scroll to bottom after adding response
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _changeStatus(QueryStatus newStatus) {
    widget.onStatusChange(newStatus);
    Navigator.pop(context); // Close the dialog
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: QueryStatus.values.map(
                  (status) => ListTile(
                title: Text(_getStatusText(status)),
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(status),
                  ),
                ),
                onTap: () => _changeStatus(status),
              ),
            ).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Query #${widget.query.id}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note),
            onPressed: _showStatusChangeDialog,
            tooltip: 'Change Status',
          ),
        ],
      ),
      body: Column(
          children: [
      // Query details section
      Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.query.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(widget.query.status),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(widget.query.status),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      _getStatusText(widget.query.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(widget.query.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              if (widget.query.isPriority)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Spacer(),
              Text(
                _formatDate(widget.query.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            widget.query.querySubject,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueGrey[100],
                radius: 18,
                child: Text(
                  widget.query.customerName.split(' ').map((e) => e[0]).join('').toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.query.customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Customer',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            widget.query.queryPreview,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),

    // Divider
    Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: Colors.grey[100],
    child: Row(
    children: [
    Icon(Icons.question_answer, size: 18, color: Colors.grey[700]),
    SizedBox(width: 8),
    Text(
    'Responses',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.grey[800],
    ),
    ),
    Spacer(),
    Text(
    '${widget.query.responses.length} ${widget.query.responses.length == 1 ? 'response' : 'responses'}',
    style: TextStyle(
    color: Colors.grey[600],
    ),
    ),
    ],
    ),
    ),

    // Messages/responses section
    Expanded(
    child: widget.query.responses.isEmpty
    ? Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
    SizedBox(height: 16),
    Text(
    'No responses yet',
    style: TextStyle(
    fontSize: 18,
    color: Colors.grey[600],
    ),
    ),
    SizedBox(height: 8),
    Text(
    'Be the first to respond to this query',
    style: TextStyle(
    color: Colors.grey[500],
    ),
    ),
    ],
    ),
    )
        : ListView.builder(
    controller: _scrollController,
    padding: EdgeInsets.all(16),
    itemCount: widget.query.responses.length,
    itemBuilder: (context, index) {
    final response = widget.query.responses[index];
    final isCustomer = response.responderName == widget.query.customerName;

    return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    CircleAvatar(
    backgroundColor: isCustomer ? Colors.blueGrey[100] : Colors.blue[100],
    radius: 18,
    child: Text(
    response.responderName.split(' ').map((e) => e[0]).join('').toUpperCase(),
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: isCustomer ? Colors.blueGrey[800] : Colors.blue[800],
    ),
    ),
    ),
    SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Text(
    response.responderName,
    style: TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    ),
    ),
    Spacer(),
    Text(
    _formatDate(response.timestamp),
    style: TextStyle(
    color: Colors.grey[600],
    fontSize: 13,
    ),
    ),
    ],
    ),
    SizedBox(height: 6),
    Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
    color: isCustomer ? Colors.grey[100] : Colors.blue[50],
    borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
    response.responseText,
    style: TextStyle(
    height: 1.5,
    ),
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    );
    },
    ),
    ),

    // Divider
    Divider(height: 1),

    // Response input section
    if (widget.query.status != QueryStatus.closed) ...[
    Container(
    padding: EdgeInsets.all(16),
    child: Row(
    children: [
    Expanded(
    child: TextField(
    controller: _responseController,
    maxLines: null,
    decoration: InputDecoration(
    hintText: 'Type your response...',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    filled: true,
    fillColor: Colors.grey[100],
    ),
    ),
    ),
    SizedBox(width: 12),
    Container(
    decoration: BoxDecoration(
    color: Colors.blue,
    shape: BoxShape.circle,
    ),
    child: IconButton(
    icon: _isLoading
    ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    )
        : Icon(Icons.send, color: Colors.white),
      onPressed: _isLoading ? null : _submitResponse,
    ),
    ),
    ],
    ),
    ),
    ] else ...[
      Container(
        padding: EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 18, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              'This query is closed and cannot be responded to',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],

            // Resolution buttons for pending or in-progress queries
            if (widget.query.status == QueryStatus.pending || widget.query.status == QueryStatus.inProgress) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('Mark as Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    widget.onStatusChange(QueryStatus.resolved);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Query marked as resolved')),
                    );
                  },
                ),
              ),
            ],

            // Reopen button for resolved or closed queries
            if (widget.query.status == QueryStatus.resolved || widget.query.status == QueryStatus.closed) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: OutlinedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Reopen Query'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    widget.onStatusChange(QueryStatus.inProgress);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Query reopened')),
                    );
                  },
                ),
              ),
            ],
          ],
      ),
    );
  }
}