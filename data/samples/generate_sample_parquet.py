import pandas as pd

data = {
    'order_id': ['AMZ-00000001', 'AMZ-00000002', 'AMZ-00000003', 'AMZ-00000004', 'AMZ-00000005'],
    'customer_id': ['CUST0001', 'CUST0002', 'CUST0003', 'CUST0004', 'CUST0005'],
    'order_datetime': pd.to_datetime(['2024-01-15 10:30:00', '2024-01-16 14:45:00', '2024-01-17 09:15:00', '2024-01-18 16:00:00', '2024-01-19 11:30:00']),
    'fulfillment_channel': ['FBA', 'FBA', 'FBM', 'FBA', 'FBA'],
    'ship_country': ['US', 'US', 'CA', 'US', 'UK'],
    'ship_state': ['CA', 'TX', None, 'NY', None],
    'ship_city': ['Los Angeles', 'Houston', 'Toronto', 'New York', 'London'],
    'product_asin': ['B08N5WRWNW', 'B09V3KXJPB', 'B07FZ8S74R', 'B08J65DST5', 'B0BDJ279KF'],
    'product_title': ['Echo Dot (4th Gen)', 'Fire TV Stick 4K', 'Instant Pot Duo 7-in-1', 'Apple AirPods Pro', 'Kindle Paperwhite'],
    'product_category': ['Electronics', 'Electronics', 'Kitchen', 'Electronics', 'Electronics'],
    'product_subcategory': ['Smart Home', 'Streaming Devices', 'Appliances', 'Headphones', 'E-Readers'],
    'quantity': [1, 2, 1, 1, 1],
    'item_price': [49.99, 79.98, 89.99, 249.99, 139.99],
    'shipping_price': [0.0, 0.0, 12.99, 0.0, 0.0],
    'tax': [4.12, 6.60, 8.24, 20.62, 0.0],
    'order_status': ['Shipped', 'Shipped', 'Shipped', 'Returned', 'Cancelled'],
    'refund_amount': [None, None, None, 249.99, 0.0]
}

df = pd.DataFrame(data)
df.to_parquet('amazon_sample.parquet', index=False)