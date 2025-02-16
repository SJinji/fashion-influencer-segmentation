-- Q1: Current Segmentation Analysis
-- Author: Jinji Shen
-- Date: 2025-02-16

-- Segment Analysis
WITH segments AS (
   SELECT 
       CASE 
           WHEN NB_FOLLOWERS IS NULL THEN 'Null'
           WHEN NB_FOLLOWERS <= 12000 THEN 'Mainstream'
           WHEN NB_FOLLOWERS <= 40000 THEN 'Trendy'
           ELSE 'Edgy'
       END as segment,
       COUNT(*) as account_count,
       AVG(NB_FOLLOWERS) as avg_followers,
       MIN(NB_FOLLOWERS) as min_followers,
       MAX(NB_FOLLOWERS) as max_followers,
       COUNT(CASE WHEN FASHION_INTEREST_SEGMENT = TRUE THEN 1 END) as fashion_interested_count
   FROM TECHTEST.TECHTEST.MART_AUTHORS_SEGMENTATIONS
   GROUP BY 1
)
SELECT 
   segment,
   account_count,
   ROUND(avg_followers, 3) as avg_followers,
   ROUND(min_followers, 3) as min_followers,
   ROUND(max_followers, 3) as max_followers,
   fashion_interested_count,
   ROUND(fashion_interested_count::float * 100 / account_count, 3) as fashion_interest_percentage
FROM segments
ORDER BY 
   CASE segment
       WHEN 'Mainstream' THEN 1
       WHEN 'Trendy' THEN 2
       WHEN 'Edgy' THEN 3
       ELSE 4
   END;

-- Engagement Analysis by Segment
WITH post_metrics AS (
    SELECT 
        s.AUTHORID,
        CASE 
           WHEN NB_FOLLOWERS IS NULL THEN 'Null'
           WHEN NB_FOLLOWERS <= 12000 THEN 'Mainstream'
           WHEN NB_FOLLOWERS <= 40000 THEN 'Trendy'
           ELSE 'Edgy'
        END as segment,
        AVG(p.NB_LIKES) as avg_likes,
        AVG(p.COMMENT_COUNT) as avg_comments,
        COUNT(DISTINCT p.POST_ID) as post_count
    FROM TECHTEST.TECHTEST.MART_AUTHORS_SEGMENTATIONS s
    JOIN TECHTEST.TECHTEST.MART_IMAGES_OF_POSTS p ON s.AUTHORID = p.AUTHORID
    GROUP BY 1, 2
)
SELECT 
    segment,
    COUNT(*) as author_count,
    ROUND(AVG(avg_likes),3) as avg_likes_per_post,
    ROUND(AVG(avg_comments),3) as avg_comments_per_post,
    ROUND(AVG(post_count),3) as avg_posts_per_author
FROM post_metrics
GROUP BY segment;

-- Engagement Rate Analysis
WITH engagement_metrics AS (
    SELECT 
        s.AUTHORID,
        s.NB_FOLLOWERS,
        AVG(p.NB_LIKES) as avg_likes,
        CASE 
            WHEN s.NB_FOLLOWERS = 0 THEN 0  -- Handle division by zero
            ELSE AVG(p.NB_LIKES::float / NULLIF(s.NB_FOLLOWERS, 0))  -- NULLIF prevents division by zero
        END as engagement_rate
    FROM TECHTEST.TECHTEST.MART_AUTHORS_SEGMENTATIONS s
    JOIN TECHTEST.TECHTEST.MART_IMAGES_OF_POSTS p ON s.AUTHORID = p.AUTHORID
    GROUP BY 1, 2
)
SELECT 
    CASE 
       WHEN NB_FOLLOWERS IS NULL THEN 'Null'
       WHEN NB_FOLLOWERS <= 12000 THEN 'Mainstream'
       WHEN NB_FOLLOWERS <= 40000 THEN 'Trendy'
       ELSE 'Edgy'
    END as segment,
    COUNT(*) as account_count,
    ROUND(AVG(CASE WHEN engagement_rate IS NOT NULL THEN engagement_rate ELSE 0 END),3) as avg_engagement_rate,
    ROUND(STDDEV(CASE WHEN engagement_rate IS NOT NULL THEN engagement_rate ELSE 0 END),3) as std_engagement_rate,
    ROUND(MIN(engagement_rate),3) as min_engagement_rate,
    ROUND(MAX(engagement_rate),3) as max_engagement_rate
FROM engagement_metrics
GROUP BY 1
ORDER BY 
    CASE segment
       WHEN 'Mainstream' THEN 1
       WHEN 'Trendy' THEN 2
       WHEN 'Edgy' THEN 3
       ELSE 4
    END;

-- Engagement Rate by Follower Range
WITH engagement_metrics AS (
   SELECT 
       s.AUTHORID,
       s.NB_FOLLOWERS,
       p.NB_LIKES,
       CASE 
           WHEN s.NB_FOLLOWERS IS NULL THEN NULL
           WHEN s.NB_FOLLOWERS = 0 THEN 0
           ELSE p.NB_LIKES::float / NULLIF(s.NB_FOLLOWERS, 0)
       END as post_engagement_rate
   FROM TECHTEST.TECHTEST.MART_AUTHORS_SEGMENTATIONS s
   JOIN TECHTEST.TECHTEST.MART_IMAGES_OF_POSTS p ON s.AUTHORID = p.AUTHORID
)
SELECT 
   CASE 
       WHEN NB_FOLLOWERS IS NULL THEN 'Null followers'
       WHEN NB_FOLLOWERS = 0 THEN 'Zero followers'
       WHEN NB_FOLLOWERS <= 1000 THEN '0-1K'
       WHEN NB_FOLLOWERS <= 5000 THEN '1K-5K'
       WHEN NB_FOLLOWERS <= 12000 THEN '5K-12K'
       WHEN NB_FOLLOWERS <= 40000 THEN '12K-40K'
       WHEN NB_FOLLOWERS <= 100000 THEN '40K-100K'
       ELSE '100K+'
   END as follower_range,
   COUNT(DISTINCT AUTHORID) as num_accounts,
   ROUND(AVG(post_engagement_rate), 3) as avg_engagement_rate,
   ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY post_engagement_rate), 3) as median_engagement_rate,
   ROUND(STDDEV(post_engagement_rate), 3) as std_engagement_rate
FROM engagement_metrics
GROUP BY 1
ORDER BY 
   CASE follower_range
       WHEN 'Null followers' THEN -1
       WHEN 'Zero followers' THEN 0
       WHEN '0-1K' THEN 1
       WHEN '1K-5K' THEN 2
       WHEN '5K-12K' THEN 3
       WHEN '12K-40K' THEN 4
       WHEN '40K-100K' THEN 5
       ELSE 6
   END;

-- Average Likes and Comments by Segment
SELECT 
    CASE 
       WHEN NB_FOLLOWERS IS NULL THEN 'Null'
       WHEN NB_FOLLOWERS <= 12000 THEN 'Mainstream'
       WHEN NB_FOLLOWERS <= 40000 THEN 'Trendy'
       ELSE 'Edgy'
    END as segment,
    ROUND(AVG(p.NB_LIKES),3) AS avg_likes,
    ROUND(AVG(p.COMMENT_COUNT),3) AS avg_comments
FROM 
    TECHTEST.TECHTEST.MART_AUTHORS_SEGMENTATIONS s
JOIN 
    TECHTEST.TECHTEST.MART_IMAGES_OF_POSTS p
ON 
    s.AUTHORID = p.AUTHORID
GROUP BY 
    segment;

-- Follow Ratio Analysis by Segment
WITH segmented_authors AS (
    SELECT 
        a.AUTHORID,
        a.NB_FOLLOWS,
        s.NB_FOLLOWERS,
        CASE 
            WHEN s.NB_FOLLOWERS IS NULL THEN 'Null'
            WHEN s.NB_FOLLOWERS <= 12000 THEN 'Mainstream'
            WHEN s.NB_FOLLOWERS <= 40000 THEN 'Trendy'
            ELSE 'Edgy'
        END as segment,
        CASE 
            WHEN s.NB_FOLLOWERS IS NULL OR s.NB_FOLLOWERS = 0 THEN NULL
            ELSE a.NB_FOLLOWS::float / s.NB_FOLLOWERS 
        END as follow_ratio
    FROM TECHTEST.TECHTEST.MART_AUTHORS_SEGMENTATIONS s
    LEFT JOIN TECHTEST.TECHTEST.MART_AUTHORS a ON s.AUTHORID = a.AUTHORID
)
SELECT 
    segment,
    COUNT(*) as account_count,
    -- Follower stats
    ROUND(AVG(NB_FOLLOWERS), 3) as avg_followers,
    ROUND(MIN(NB_FOLLOWERS), 3) as min_followers,
    ROUND(MAX(NB_FOLLOWERS), 3) as max_followers,
    -- Following stats
    ROUND(AVG(NB_FOLLOWS), 3) as avg_follows,
    ROUND(MIN(NB_FOLLOWS), 3) as min_follows,
    ROUND(MAX(NB_FOLLOWS), 3) as max_follows,
    -- Follow ratio stats
    ROUND(AVG(follow_ratio), 3) as avg_follow_ratio,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY follow_ratio), 3) as median_follow_ratio,
    ROUND(STDDEV(follow_ratio), 3) as std_follow_ratio
FROM segmented_authors
GROUP BY segment
ORDER BY 
    CASE segment
        WHEN 'Mainstream' THEN 1
        WHEN 'Trendy' THEN 2
        WHEN 'Edgy' THEN 3
        ELSE 4
    END;