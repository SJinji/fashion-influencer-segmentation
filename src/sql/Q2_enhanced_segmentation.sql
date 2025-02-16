-- Q2: Enhanced Segmentation 
-- Author: Jinji Shen
-- Date: 2025-02-16

WITH 
-- Step 1: Create base author segments with NULL handling
account_base AS (
    SELECT 
        AUTHORID,
        NB_FOLLOWERS,
        CASE 
            WHEN NB_FOLLOWERS IS NULL THEN 'Null'
            WHEN NB_FOLLOWERS <= 12000 THEN 'Mainstream'
            WHEN NB_FOLLOWERS <= 40000 THEN 'Trendy'
            ELSE 'Edgy'
        END AS influence_tier
    FROM MART_AUTHORS_SEGMENTATIONS
),

-- Step 2: Calculate engagement metrics with NULL handling
engagement_metrics AS (
    SELECT 
        p.AUTHORID,
        COUNT(DISTINCT p.IMAGE_ID) as total_posts,
        COALESCE(AVG(NULLIF(p.NB_LIKES, 0)), 0) as avg_likes,
        COALESCE(AVG(NULLIF(p.COMMENT_COUNT, 0)), 0) as avg_comments,
        -- Engagement rate calculation
        CASE 
            WHEN a.NB_FOLLOWERS > 0 THEN 
                COALESCE(AVG(NULLIF(p.NB_LIKES, 0)), 0) / a.NB_FOLLOWERS
            ELSE 0
        END as engagement_rate
    FROM MART_IMAGES_OF_POSTS p
    JOIN account_base a ON p.AUTHORID = a.AUTHORID
    GROUP BY p.AUTHORID, a.NB_FOLLOWERS
),

-- Step 3: Analyze content patterns
content_patterns AS (
    SELECT 
        p.AUTHORID,
        l.LABEL_NAME,
        COUNT(*) as label_count,
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY p.AUTHORID) as label_percentage
    FROM MART_IMAGES_OF_POSTS p
    JOIN MART_IMAGES_LABELS l ON p.IMAGE_ID = l.IMAGE_ID
    GROUP BY p.AUTHORID, l.LABEL_NAME
),

-- Step 4: Calculate content diversity
content_diversity AS (
    SELECT 
        cp.AUTHORID,
        COUNT(DISTINCT cp.LABEL_NAME) as label_diversity,
        -- Calculate weighted diversity score
        SUM(CASE 
            WHEN cp.label_percentage >= 20 THEN 3
            WHEN cp.label_percentage >= 10 THEN 2
            ELSE 1
        END) as diversity_score
    FROM content_patterns cp
    GROUP BY cp.AUTHORID
),

-- Step 5: Create fashion-specific metrics
fashion_metrics AS (
    SELECT 
        p.AUTHORID,
        
        -- Footwear Categories
        SUM(CASE 
            WHEN l.LABEL_NAME IN (
                'sneakerlowtop', 'pumps', 'canvastypesneakers', 'heelblock', 'duckboots',
                'bootshiking', 'mulesneakers', 'sneakersskater', 'sandalankle', 'flatheel',
                'sandalscutout', 'sandals', 'bootssockpullon', 'bootsmidcalf', 'sandalstbar',
                'sneakerhightop', 'sneakersplitsegmented', 'trainerrunninsneakers', 'sneakerplatform',
                'rainboots', 'sneakers', 'pumpsderby', 'dressboots', 'sneakerstennis', 
                'sneakersbasketball', 'sneakerslimsole', 'sneakersrunning', 'sandalsclassicstraps',
                'sneakersretrorunning', 'sneakersegmented', 'sneakerscourt', 'sneakersother',
                'sneakerssockpullon', 'sandalscrisscross', 'slingback', 'plainpumps', 'sliponsneakers',
                'sportbasketballsneakers', 'pumpsclogs', 'pumpsmaryjane', 'retrofootballsneakers',
                'bootsankle', 'pumpsmoccassins', 'bootscombat', 'bootsthighhigh', 'boots'
            ) THEN 1 
            ELSE 0 
        END) AS footwear_count,
        
        -- Clothing Categories
        SUM(CASE 
            WHEN l.LABEL_NAME IN (
                'coat', 'pants', 'dress', 'top', 'underpants', 'shorts', 'skirt', 'bra',
                'shoes', 'socks', 'closedback', 'flatform'
            ) THEN 1 
            ELSE 0 
        END) AS clothing_count,
        
        -- Accessories Categories
        SUM(CASE 
            WHEN l.LABEL_NAME IN (
                'earring', 'eyewear', 'wristlet', 'bag', 'neckwear', 'belt', 'hat', 'umbrella',
                'sunglasses', 'watch', 'scarf', 'gloves', 'handbag'
            ) THEN 1 
            ELSE 0 
        END) AS accessories_count,
        
        -- Luxury Brands
        SUM(CASE 
            WHEN l.LABEL_NAME IN (
                'chanel', 'saintlaurent', 'jacquemus', 'gucci', 'givenchy', 'louisvuitton',
                'hermes', 'fendi', 'prada', 'dior', 'chloe', 'balenciaga', 'new_balance',
                'nike', 'louboutin', 'miu_miu', 'ysl', 'adidas', 'jimmychoo', 'celine',
                'bottegaveneta', 'burberry', 'alexandermcqueen'
            ) THEN 1 
            ELSE 0 
        END) AS luxury_count,
        
        -- Sportswear Categories
        SUM(CASE 
            WHEN l.LABEL_NAME IN (
                'sneakerlowtop', 'sneakersrunning', 'trainerrunninsneakers', 'sportbasketballsneakers',
                'sneakersbasketball', 'sneakersretrorunning', 'sneakersegmented', 'sneakerscourt',
                'sneakersother', 'sneakerssockpullon', 'sneakerssplitsegmented', 'sneakerplatform',
                'sneakerhightop', 'sneakerslimsole', 'sneakersskater', 'sneakers', 'bootshiking',
                'bootscombat', 'bootsthighhigh', 'bootsankle', 'boots'
            ) THEN 1 
            ELSE 0 
        END) AS sportswear_count,
        
        -- Patterns & Designs
        SUM(CASE 
            WHEN l.LABEL_NAME IN (
                'stripes', 'pinstripes', 'tiedye', 'zebra', 'giraffe', 'leopard', 'camouflage',
                'sequin', 'dots', 'flowers', 'checked', 'plain', 'bigpadded', 'checkerboard',
                'colourlayeredsole', 'allover', 'basicdenim', 'orange', 'cow'
            ) THEN 1 
            ELSE 0 
        END) AS pattern_count
    FROM MART_IMAGES_OF_POSTS p
    JOIN MART_IMAGES_LABELS l ON p.IMAGE_ID = l.IMAGE_ID
    GROUP BY p.AUTHORID
)

-- Final segmentation combining all metrics
SELECT 
    ab.AUTHORID,
    ab.NB_FOLLOWERS,
    ab.influence_tier,
    em.total_posts,
    ROUND(em.engagement_rate::numeric, 4) as engagement_rate,
    cd.label_diversity,
    cd.diversity_score,
    fm.footwear_count,
    fm.clothing_count,
    fm.accessories_count,
    fm.luxury_count,
    fm.sportswear_count,
    fm.pattern_count,
    
    -- Create detailed segment label
    CASE 
        -- Handle NULL influence tier first
        WHEN ab.influence_tier = 'Null' THEN 
            'Undefined Account Profile'
            
        -- Luxury Fashion Segments
        WHEN fm.luxury_count > 5 THEN
            ab.influence_tier || ' Luxury Fashion'
            
        -- Sportswear Segments
        WHEN fm.sportswear_count > 5 THEN
            ab.influence_tier || ' Sportswear Focus'
            
        -- High Diversity Fashion
        WHEN cd.diversity_score >= 10 THEN
            ab.influence_tier || ' Fashion Curator'
            
        -- Footwear Specialists
        WHEN fm.footwear_count > fm.accessories_count AND fm.footwear_count > fm.clothing_count THEN
            ab.influence_tier || ' Footwear Specialist'
            
        -- Accessories Specialists
        WHEN fm.accessories_count > fm.footwear_count AND fm.accessories_count > fm.clothing_count THEN
            ab.influence_tier || ' Accessories Specialist'
            
        -- Style Focus
        WHEN fm.pattern_count > 5 THEN
            ab.influence_tier || ' Style Trendsetter'
            
        -- Default Category
        ELSE ab.influence_tier || ' Fashion General'
    END || 
    CASE 
        WHEN em.engagement_rate > PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY em.engagement_rate) OVER()
        THEN ' (High Engagement)'
        ELSE ''
    END as fashion_segment,
    
    -- Add engagement level as separate column
    CASE 
        WHEN em.engagement_rate > PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY em.engagement_rate) OVER()
        THEN 'High'
        WHEN em.engagement_rate > PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY em.engagement_rate) OVER()
        THEN 'Medium'
        ELSE 'Standard'
    END as engagement_level

FROM account_base ab
LEFT JOIN engagement_metrics em ON ab.AUTHORID = em.AUTHORID
LEFT JOIN content_diversity cd ON ab.AUTHORID = cd.AUTHORID
LEFT JOIN fashion_metrics fm ON ab.AUTHORID = fm.AUTHORID
ORDER BY 
    CASE ab.influence_tier 
        WHEN 'Edgy' THEN 1
        WHEN 'Trendy' THEN 2
        WHEN 'Mainstream' THEN 3
        ELSE 4
    END,
    em.engagement_rate DESC NULLS LAST;