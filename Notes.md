### the primary keys : 

the combo between droppoff and pickup coordinates of the ride was choosen as the primary key for the dataset.

#### why ?:

every ride is unique in terms of its pickup and dropoff coordinates, which makes this combination a suitable primary key. This ensures that each record in the dataset can be uniquely identified by its specific pickup and dropoff locations, preventing any duplication of rides in the dataset.

#### BUUUUUUT ? : 

*i started with smaple data from july 2020*
During the data cleaning process, it was observed that there were instances where multiple rides had the same pickup and dropoff coordinates. which means that the combination of pickup and dropoff coordinates was not always unique.

so i started to look for a better primary key that could uniquely identify each ride in the dataset, but after some research and analysis, o realized that only by adding the some pricing information (*'total_amount'*) to the primary key it will increase the cardinality to 100% , it was weird to me , cuz why would the same pickup and dropoff coordinates have different prices ?

after further investigation, it was found that for some rides, the same ride has two differenent price , positive and negative, which means that the same ride was recorded twice in the dataset with different pricing information. 

this can be explained by the fact that some rides may have been canceled or refunded, resulting in a negative price for the same ride.


my hypothesis are :  Vendor issued a refund by creating a negative transaction , and the original transaction was still recorded in the dataset, resulting in two records for the same ride with different pricing information.

well i just found out that most negative trips has payment_type = 4 and 3, which are associated with "No charge" and "Dispute" payment types, respectively. This further supports the idea that these negative trips are likely due to refunds or disputes.

but i still have two payment records which are negative but have payment type  1 and 2.


so at the end i quarinted the dataset to only include rides with positive pricing information, which allowed me to use the combination of pickup and dropoff coordinates as the primary key for the dataset . 

also i added a new column called 'is_revers' to indicate whether a ride was refunded or not, which will help in future analysis of the dataset.