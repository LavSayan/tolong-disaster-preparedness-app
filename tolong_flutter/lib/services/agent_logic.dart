import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class DisasterAgent {
  List<dynamic> _clusterCentroids = [];
  List<dynamic> _evacuationCenters = [];
  bool _isTrainedModelLoaded = false;

  /// Step 1: Load offline JSON artifacts from assets/data/
  Future<void> initializeAgent() async {
    try {
      // Load trained weights generated from Google Colab K-Means script
      final String weightsString =
          await rootBundle.loadString('assets/data/agent_trained_weights.json');
      final Map<String, dynamic> weightsJson = json.decode(weightsString);
      _clusterCentroids = weightsJson['cluster_centroids'] ?? [];

      // Load evacuation centers dataset
      final String centersString =
          await rootBundle.loadString('assets/data/evacuation_centers_dev.json');
      final Map<String, dynamic> centersJson = json.decode(centersString);
      _evacuationCenters = centersJson['centers'] ?? [];

      _isTrainedModelLoaded = true;
      print('DisasterAgent successfully loaded trained model with ${_clusterCentroids.length} centroids.');
    } catch (e) {
      print('Error initializing DisasterAgent: $e');
    }
  }

  /// Helper: Euclidean Distance between two geographic points (lat, lng)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return sqrt(pow(lat1 - lat2, 2) + pow(lng1 - lng2, 2));
  }

  /// Step 2: Determine which trained K-Means cluster centroid the user belongs to
  int getAssignedCluster(double userLat, double userLng) {
    if (!_isTrainedModelLoaded || _clusterCentroids.isEmpty) return -1;

    int nearestClusterIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < _clusterCentroids.length; i++) {
      final double centroidLat = _clusterCentroids[i][0];
      final double centroidLng = _clusterCentroids[i][1];

      final double distance = _calculateDistance(userLat, userLng, centroidLat, centroidLng);
      if (distance < minDistance) {
        minDistance = distance;
        nearestClusterIndex = i;
      }
    }

    return nearestClusterIndex;
  }

  /// Step 3: Multi-Attribute Decision-Making (MADM)
  /// Evaluates and ranks evacuation centers based on user location and shelter characteristics
  Map<String, dynamic>? recommendEvacuationCenter(double userLat, double userLng) {
    if (_evacuationCenters.isEmpty) return null;

    Map<String, dynamic>? bestCenter;
    double highestScore = -1.0;

    for (var center in _evacuationCenters) {
      final double centerLat = (center['lat'] as num).toDouble();
      final double centerLng = (center['lng'] as num).toDouble();

      // Attribute 1: Proximity Score (Inverse of distance)
      final double dist = _calculateDistance(userLat, userLng, centerLat, centerLng);
      final double proximityScore = 1.0 / (dist + 0.0001); // Prevent division by zero

      // Attribute 2: Facility Suitability Multiplier
      double facilityWeight = 1.0;
      final String facilityType = center['facilityType'] ?? '';
      if (facilityType == 'school') {
        facilityWeight = 1.2; // Preferred emergency shelter type
      } else if (facilityType == 'coveredCourt') {
        facilityWeight = 1.1;
      }

      // Total Utility Score = Proximity x Facility Weight
      final double totalScore = proximityScore * facilityWeight;

      if (totalScore > highestScore) {
        highestScore = totalScore;
        bestCenter = Map<String, dynamic>.from(center);
        bestCenter['computed_score'] = totalScore;
      }
    }

    return bestCenter;
  }
}
