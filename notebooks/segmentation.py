import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.pipeline import make_pipeline
from sklearn.metrics import silhouette_score
import logging
import matplotlib.pyplot as plt
from sklearn.feature_extraction.text import TfidfTransformer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('FashionSegmentation')

# Fashion label taxonomy - 132 curated labels
FASHION_LABELS = [
    # Footwear (45 items)
    'sneakerlowtop', 'pumps', 'canvastypesneakers', 'heelblock', 'duckboots',
    'bootshiking', 'mulesneakers', 'sneakersskater', 'sandalankle', 'flatheel',
    'sandalscutout', 'sandals', 'bootssockpullon', 'bootsmidcalf', 'sandalstbar',
    'sneakerhightop', 'sneakersplitsegmented', 'trainerrunninsneakers', 'sneakerplatform',
    'rainboots', 'sneakers', 'pumpsderby', 'dressboots', 'sneakerstennis', 
    'sneakersbasketball', 'sneakerslimsole', 'sneakersrunning', 'sandalsclassicstraps',
    'sneakersretrorunning', 'sneakersegmented', 'sneakerscourt', 'sneakersother',
    'sneakerssockpullon', 'sandalscrisscross', 'slingback', 'plainpumps', 'sliponsneakers',
    'sportbasketballsneakers', 'pumpsclogs', 'pumpsmaryjane', 'retrofootballsneakers',
    'bootsankle', 'pumpsmoccassins', 'bootscombat', 'bootsthighhigh', 'boots',

    # Clothing (12)
    'coat', 'pants', 'dress', 'top', 'underpants', 'shorts', 'skirt', 'bra',
    'shoes', 'socks', 'closedback', 'flatform',

    # Accessories (13)
    'earring', 'eyewear', 'wristlet', 'bag', 'neckwear', 'belt', 'hat', 'umbrella',
    'sunglasses', 'watch', 'scarf', 'gloves', 'handbag',

    # Designer Brands (23)
    'chanel', 'saintlaurent', 'jacquemus', 'gucci', 'givenchy', 'louisvuitton',
    'hermes', 'fendi', 'prada', 'dior', 'chloe', 'balenciaga', 'new_balance',
    'nike', 'louboutin', 'miu_miu', 'ysl', 'adidas', 'jimmychoo', 'celine',
    'bottegaveneta', 'burberry', 'alexandermcqueen',

    # Materials & Fabrics (12)
    'tulle', 'velvet', 'linen', 'tweed', 'fur', 'mesh', 'mohair', 'suede',
    'satin', 'leather', 'taffeta', 'vinyl',

    # Patterns & Designs (19)
    'stripes', 'pinstripes', 'tiedye', 'zebra', 'giraffe', 'leopard', 'camouflage',
    'sequin', 'dots', 'flowers', 'checked', 'plain', 'bigpadded', 'checkerboard',
    'colourlayeredsole', 'allover', 'basicdenim', 'orange', 'cow',

    # Shoe Components (28)
    'singlesole', 'heelmid', 'bubblesole', 'heeled', 'heelflat', 'openback',
    'closurevelcro', 'closurelacing', 'toealmond', 'toeround', 'toepointy',
    'heelstiletto', 'heelcone', 'lugsole', 'closuredrawstring', 'heelhigh',
    'extendedsole', 'solerubber', 'noheel', 'muleback', 'sandalsstrappy',
    'sandalmidcalf', 'heellow', 'heelskinny', 'closurebuckle', 'sandalsthong',
    'flatpumpsballerina', 'pumpsespadrille', 'heelchunky', 'heelflared',
    'closuredoublebuckle'
]

class FashionSegmenter:
    def __init__(self, posts_df, labels_df, segmentations_df):
        self.posts_df = posts_df
        self.labels_df = labels_df
        self.segmentations_df = segmentations_df
        
        # Initialize preprocessing
        self._preprocess_data()  # Now properly defined below
        self.label_pairs = self._create_label_pairs()

    def _preprocess_data(self):
        """Clean and prepare raw data"""
        # Convert numeric columns
        self.posts_df['NB_LIKES'] = pd.to_numeric(
            self.posts_df['NB_LIKES'], 
            errors='coerce'
        ).fillna(0)
        
        self.segmentations_df['NB_FOLLOWERS'] = pd.to_numeric(
            self.segmentations_df['NB_FOLLOWERS'],
            errors='coerce'
        ).fillna(0)
        
        # Clean label data
        self.labels_df = self.labels_df.dropna(subset=['LABEL_NAME'])

    def _create_label_pairs(self):
        """Create author-label pairs with deduplication"""
        author_images = self.posts_df[['AUTHORID', 'IMAGE_ID']].drop_duplicates()
        fashion_labels = self.labels_df[self.labels_df['LABEL_NAME'].isin(FASHION_LABELS)]
        
        return author_images.merge(
            fashion_labels[['IMAGE_ID', 'LABEL_NAME']],
            on='IMAGE_ID',
            how='inner'
        )

    def _get_label_features(self):
        """Create TF-IDF weighted label features"""
        # Create count matrix
        label_counts = pd.crosstab(
            self.label_pairs['AUTHORID'],
            self.label_pairs['LABEL_NAME']
        )
        
        # Apply TF-IDF transformation
        tfidf = TfidfTransformer()
        tfidf_features = tfidf.fit_transform(label_counts)
        
        return pd.DataFrame(
            tfidf_features.toarray(),
            columns=label_counts.columns,
            index=label_counts.index
        ).add_prefix('fashion_')

    def _get_engagement_features(self):
        """Combine absolute and relative engagement"""
        engagement = self.posts_df.groupby('AUTHORID').agg(
            total_likes=('NB_LIKES', 'sum'),
            post_count=('POST_ID', 'nunique')
        )
        
        # Merge with follower data
        engagement = engagement.join(
            self.segmentations_df.set_index('AUTHORID')['NB_FOLLOWERS'],
            how='left'
        ).fillna(1)
        
        # Create robust metrics
        engagement['abs_engagement'] = np.log1p(engagement['total_likes'])
        engagement['rel_engagement'] = engagement['total_likes'] / engagement['NB_FOLLOWERS'].replace(0, 1)
        
        return engagement[['abs_engagement', 'rel_engagement', 'post_count']]

    def create_feature_matrix(self):
        """Combine all features into final matrix"""
        logger.info("Creating feature matrix...")
        
        # Get base features
        label_features = self._get_label_features()
        engagement_features = self._get_engagement_features()
        
        # Combine features and clean
        features = label_features.join(engagement_features, how='left').fillna(0)
        
        # Add follower tiers
        features['follower_tier'] = pd.cut(
            self.segmentations_df.set_index('AUTHORID')['NB_FOLLOWERS'],
            bins=[0, 12000, 40000, float('inf')],
            labels=['micro', 'mid', 'macro']
        ).astype(str)
        
        # Final cleanup
        features = features.replace([np.inf, -np.inf], 0)
        return features

    def find_optimal_clusters(self, features, max_k=8):
        """Determine optimal number of clusters using silhouette score"""
        logger.info("Finding optimal cluster count...")
        
        # Preprocessing pipeline with infinity guard
        preprocessor = make_pipeline(
            StandardScaler(),
            PCA(0.95)
        )
        
        try:
            X = preprocessor.fit_transform(features.select_dtypes(include=np.number))
        except ValueError as e:
            logger.error("Data contains invalid values after preprocessing. Check for NaNs/infs.")
            raise
        
        best_k = 3
        best_score = -1
        
        for k in range(2, max_k+1):
            kmeans = KMeans(n_clusters=k, random_state=42)
            labels = kmeans.fit_predict(X)
            score = silhouette_score(X, labels)
            
            if score > best_score:
                best_score = score
                best_k = k
                
        logger.info(f"Optimal clusters: {best_k} (silhouette: {best_score:.2f})")
        return best_k

    def create_segments(self, features, n_clusters=5):
        """Use Gaussian Mixture Model for better cluster separation"""
        from sklearn.mixture import GaussianMixture
        
        # Preprocessing pipeline
        preprocessor = make_pipeline(
            StandardScaler(),
            PCA(0.95)
        )
        
        X = preprocessor.fit_transform(features.select_dtypes(include=np.number))
        
        # Cluster with GMM
        gmm = GaussianMixture(
            n_components=n_clusters,
            random_state=42,
            reg_covar=1e-3  # Prevent singularities
        )
        features['cluster'] = gmm.fit_predict(X)
        
        return self._label_clusters(features)

    def _label_clusters(self, features):
        """Rule-based labeling combining features"""
        cluster_rules = {
            0: {
                'conditions': [
                    ('fashion_chanel', 0.8),
                    ('rel_engagement', 0.1),
                    ('abs_engagement', 5)
                ],
                'label': "Luxury Fashion Influencers"
            },
            1: {
                'conditions': [
                    ('fashion_sneakerlowtop', 0.7),
                    ('post_count', 50)
                ],
                'label': "Sneaker Culture Enthusiasts"
            },
            2: {
                'conditions': [
                    ('fashion_engagement_rate', 0.05),
                    ('follower_tier', 'macro')
                ],
                'label': "General Fashion Macro-Influencers"
            }
        }
        
        features['segment'] = 'Other'
        for cluster, rules in cluster_rules.items():
            mask = features['cluster'] == cluster
            for feature, threshold in rules['conditions']:
                mask &= features[feature] > threshold
            features.loc[mask, 'segment'] = rules['label']
        
        return features
        

def main():
    # Load data (update paths as needed)
    posts_df = pd.read_csv('/Users/jinjishen/Desktop/my_new_project/heuritech_analysis/data/MART_IMAGES_OF_POSTS.csv')
    labels_df = pd.read_csv('/Users/jinjishen/Desktop/my_new_project/heuritech_analysis/data/MART_IMAGES_LABELS.csv')
    segmentations_df = pd.read_csv('/Users/jinjishen/Desktop/my_new_project/heuritech_analysis/data/MART_AUTHORS_SEGMENTATIONS.csv')

    # Initialize segmenter
    segmenter = FashionSegmenter(posts_df, labels_df, segmentations_df)
    
    try:
        # Feature engineering
        features = segmenter.create_feature_matrix()
        
        # Cluster analysis
        optimal_k = segmenter.find_optimal_clusters(features)
        segmented = segmenter.create_segments(features, optimal_k)
        
        # Save results
        segmented.to_csv('fashion_segments.csv', index=True)
        print("\nSegmentation Results:")
        print(segmented['segment'].value_counts().to_string())
        
    except Exception as e:
        logger.error(f"Segmentation failed: {str(e)}")
        raise

if __name__ == "__main__":
    main()