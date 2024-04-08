import 'package:kmeans_cluster/kmeans.dart';
import 'package:test/test.dart';

void main() {
  group('Cluster tests', () {
    test('Calculates mean correctly for non-empty cluster', () {
      final cluster = Cluster(1);
      cluster.add('key1', 10);
      cluster.add('key2', 20);
      cluster.add('key3', 30);

      expect(cluster.mean, equals(20.0));
    });

    test('Calculates mean as 0 for empty cluster', () {
      final cluster = Cluster(1);
      expect(cluster.mean, equals(0));
    });

    test('Adds data point to cluster correctly', () {
      final cluster = Cluster(1);
      cluster.add('key', 10);

      expect(cluster.data, containsPair('key', 10.0));
    });

    test('Calculates sum of squared distances correctly', () {
      final cluster = Cluster(1);
      cluster.add('key1', 10);
      cluster.add('key2', 20);
      cluster.add('key3', 30);

      expect(cluster.sumSquaredDistances, equals(200.0));
    });

    test('Returns set of member keys correctly', () {
      final cluster = Cluster(1);
      cluster.add('key1', 10);
      cluster.add('key2', 20);
      cluster.add('key3', 30);

      expect(cluster.members, equals({'key1', 'key2', 'key3'}));
    });

    test('Calculates distance to another cluster correctly', () {
      final cluster1 = Cluster(1);
      cluster1.add('key1', 10);
      cluster1.add('key2', 20);
      cluster1.add('key3', 30);

      final cluster2 = Cluster(2);
      cluster2.add('key1', 15);
      cluster2.add('key2', 25);
      cluster2.add('key3', 35);

      expect(cluster1.distanceTo(cluster2), equals(5.0));
    });

    test('Returns string representation of cluster correctly', () {
      final cluster = Cluster(1);
      cluster.add('key1', 10);
      cluster.add('key2', 20);
      cluster.add('key3', 30);

      expect(cluster.toString(), equals('Cluster 1 (mean: 20.0, members: [key1, key2, key3])'));
    });
  });

  group('KMeansClusterer tests', () {
    test('Returns empty clusters and index when data is empty', () {
      final clusterer = KMeansClusterer({});
      clusterer.cluster();

      expect(clusterer.clusters, isEmpty);
      expect(clusterer.index, isEmpty);
    });

    test('Creates single cluster with one data point', () {
      final clusterer = KMeansClusterer({'key': 10.0});
      clusterer.cluster();

      expect(clusterer.clusters.length, equals(1));
      expect(clusterer.clusters.first.members, equals({'key'}));
      expect(clusterer.index, containsPair('key', clusterer.clusters.first));
    });

    test('Creates two clusters with two distinct data points', () {
      final clusterer = KMeansClusterer({'key1': 10.0, 'key2': 20.0});
      clusterer.cluster();

      expect(clusterer.clusters.length, equals(2));
      if (clusterer.clusters[0].members.contains('key1')) {
        expect(clusterer.clusters[0].members, equals({'key1'}));
        expect(clusterer.clusters[1].members, equals({'key2'}));
        expect(clusterer.index, containsPair('key1', clusterer.clusters[0]));
        expect(clusterer.index, containsPair('key2', clusterer.clusters[1]));
      } else {
        expect(clusterer.clusters[0].members, equals({'key2'}));
        expect(clusterer.clusters[1].members, equals({'key1'}));
        expect(clusterer.index, containsPair('key2', clusterer.clusters[0]));
        expect(clusterer.index, containsPair('key1', clusterer.clusters[1]));
      }
    });

    test('Creates one clusters with close data points', () {
      final clusterer = KMeansClusterer({'key1': 10.0, 'key2': 11.0});
      clusterer.cluster();

      expect(clusterer.clusters.length, equals(1));
      expect(clusterer.clusters.first.members, equals({'key1', 'key2'}));
      expect(clusterer.index, containsPair('key1', clusterer.clusters.first));
      expect(clusterer.index, containsPair('key2', clusterer.clusters.first));
    });

    test('Finds optimal K correctly', () {
      final clusterer = KMeansClusterer({
        'key1': 10.0,
        'key2': 20.0,
        'key3': 30.0,
        'key4': 40.0,
        'key5': 50.0,
        'key6': 60.0,
        'key7': 70.0,
        'key8': 80.0,
        'key9': 90.0,
        'key10': 100.0,
      });

      final optimalK = clusterer.findOptimalK(clusterer.data, 5);
      expect(optimalK, equals(2));
    });
  });
}
