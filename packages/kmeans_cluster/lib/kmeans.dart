import 'dart:math';

import 'package:kmeans/kmeans.dart';

/// Represents a cluster of data points with
/// a mean and members identified by their keys.
class Cluster {
  /// Unique identifier for the cluster.
  final int id;

  /// The mean value of the data points in the cluster.
  final double mean;

  /// A mapping of keys to their corresponding data points in the cluster.
  final Map<String, double> data;

  /// Creates a [Cluster] with a given [id] and [mean].
  Cluster(this.id, this.mean) : data = {};

  /// Gets a set of all member keys in the cluster.
  Set<String> get members => data.keys.toSet();

  /// Adds a data point to the cluster with the provided [key] and [value].
  void add(String key, double value) {
    data[key] = value;
  }

  /// Calculates the Euclidean distance to another cluster based on mean values.
  double distanceTo(Cluster other) {
    return (mean - other.mean).abs();
  }

  @override
  String toString() => 'Cluster $id (members: $members, mean: $mean)';
}

/// A class that performs K-Means clustering on a set of data points.
class KMeansClusterer {
  /// The data points to be clustered, mapped by their keys.
  final Map<String, double> data;

  /// The list of clusters created after the clustering process.
  List<Cluster> clusters = [];

  /// An index to quickly find the cluster for a given key.
  Map<String, Cluster> index = {};

  /// Creates a [KMeansClusterer] with the provided [data].
  KMeansClusterer(this.data);

  List<Cluster> get outliers {
    // Calculate the average number of data points per cluster.
    final double meanDataPointsPerCluster =
        clusters.fold(0, (sum, cluster) => sum + cluster.data.length) / clusters.length;

    // Calculate the average distance between cluster means.
    List<double> distances = List.generate(clusters.length, (i) {
      return List.generate(clusters.length,
          (j) => i != j ? clusters[i].distanceTo(clusters[j]) : double.infinity).reduce(min);
    });

    // Calculate the average distance.
    final double meanDistance = distances.reduce((a, b) => a + b) / distances.length;

    // Thresholds for what is considered an outlier cluster.
    const double distanceFactor = 1.5;
    const double sparsityFactor = 0.5;

    // Identify the clusters that are outliers based on sparsity and distance.
    List<Cluster> outliers = [];
    for (int i = 0; i < clusters.length; i++) {
      if (clusters[i].data.length < meanDataPointsPerCluster * sparsityFactor &&
          distances[i] > meanDistance * distanceFactor) {
        outliers.add(clusters[i]);
      }
    }

    return outliers;
  }

  /// Converts the map of data points into a list of lists for K-Means processing.
  List<List<double>> get points => data.values.map((e) => [e]).toList();

  /// Retrieves the cluster for the provided [key], if it exists.
  Cluster? operator [](String key) => index[key];

  /// Performs clustering using the K-Means algorithm with parameters to find the best fit.
  void cluster({
    int maxIterations = 300,
    int seed = 42,
    int minK = 2,
    int maxK = 20,
    int trialsPerK = 1,
    KMeansInitializer init = KMeansInitializers.kMeansPlusPlus,
    double tolerance = 1e-4,
    bool useExactSilhouette = false,
  }) {
    var kmeans = KMeans(points);
    var clusterData = kmeans.bestFit(
      maxIterations: maxIterations,
      seed: seed,
      minK: minK,
      maxK: maxK,
      trialsPerK: trialsPerK,
      init: init,
      tolerance: tolerance,
      useExactSilhouette: useExactSilhouette,
    );

    _createClusters(clusterData);
  }

  /// Create [Cluster] instances based on clustering data.
  void _createClusters(Clusters clusterData) {
    clusters = List.generate(clusterData.k, (index) => Cluster(index, clusterData.means[index][0]));
    List<String> keys = data.keys.toList();

    for (int i = 0; i < clusterData.clusters.length; i++) {
      int clusterIndex = clusterData.clusters[i];
      String key = keys[i];
      double value = data[key]!;
      clusters[clusterIndex].add(key, value);
      index[key] = clusters[clusterIndex];
    }
  }
}
