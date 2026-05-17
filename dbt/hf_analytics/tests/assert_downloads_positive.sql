-- Test: No model should have negative downloads
-- If this query returns ANY rows, the test FAILS

select
    model_id,
    downloads_count,
    'Negative downloads detected' as failure_reason
from {{ ref('fact_model_activity') }}
where downloads_count < 0 