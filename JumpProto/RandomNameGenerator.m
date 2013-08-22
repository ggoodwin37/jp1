//
//  RandomNameGenerator.m
//  JumpProto
//
//  Created by Gideon iOS on 7/28/13.
//
//

#import "RandomNameGenerator.h"

@implementation RandomNameGenerator

+(int)countList:(NSString **)list
{
    int p = 0;
    while( list[p] != nil ) ++p;
    return p;
}

//                  @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",

+(NSArray *)getCol0List
{
    static NSArray *list0 = nil;
    if( list0 == nil )
    {
        list0 = [[NSArray arrayWithObjects: @"Harold", @"Harvey", @"Maude", @"Ellen", @"Fritz", @"Ogden", @"Jorge", @"Jesus", @"Mia", @"Davis",
                  @"Gatsby", @"Riordan", @"Jordan", @"Fitzpatrick", @"Smedley", @"Dr. Biggs", @"Templeton", @"Jarvis", @"Conrad", @"Joe",
                  @"Boris", @"Wendy", @"Carlos", @"Dana", @"Patrick", @"Patricia", @"Gladys", @"Phillis", @"Theresa", @"Lois",
                  @"Gunnar", @"Blupus", @"Your Mom", @"Russel", @"Jove", @"Conroy", @"Lolita", @"Andrew", @"Nancy",@"Claude",
                  @"Evan", @"Bradley", @"Your Dad", @"Einstein", @"Snake McCoy", @"Jorgenson", @"Fred", @"Old Man Keane", @"Harry", @"Roland",
                  @"Andrea", @"Rosie", @"Irwin", @"The Janitor", @"The Baker", @"The Professional", @"Oscar", @"Ms. Fizz", @"Nero", @"Victor",
                  @"Gandalf", @"Mr. Gein", @"Zachary", @"Prometheus", @"Stuart", @"Dr. Wobble", @"Your Brother", @"Finnegan", @"Monty", @"Zoe",
                  nil ] retain];
    };
    return list0;
}


+(NSArray *)getCol1List
{
    static NSArray *list1 = nil;
    if( list1 == nil )
    {
        list1 = [[NSArray arrayWithObjects: @"boisterous", @"vociferous", @"ambiguous", @"glistening",
                  @"throbbing", @"amorphous", @"duplicitous", @"scandalous", @"precarious", @"stationary",
                  @"mobile", @"unambiguous", @"traiterous", @"hot", @"unhappy", @"disciplined", @"amorous", @"stealthy", @"subtle", @"vulgar",
                  @"keen", @"spacious", @"frugal", @"calculating", @"compact", @"bargain", @"generic", @"lewd", @"trustworthy", @"valiant",
                  @"stout", @"rotten", @"fragrant", @"responsive", @"silly", @"softspoken", @"precious", @"pithy", @"remote", @"tilted",
                  @"nasty", @"ugly", @"synthetic", @"atrophied", @"burlesque", @"small", @"large", @"giant", @"grandiose", @"dubious",
                  @"affected", @"complacent", @"old-fashioned", @"obscene", @"reinforced", @"streamlined", @"aerodynamic", @"ponderous", @"abyssmal", @"unusual",
                  @"flat", @"pointy", @"spooky", @"boring", @"circuitous", @"straightforward", @"embarassing", @"garden-variety", @"contagious", @"subterranean",
                  nil] retain];
    };
    return list1;
}


+(NSArray *)getCol2List
{
    static NSArray *list2 = nil;
    if( list2 == nil )
    {
        list2 = [[NSArray arrayWithObjects: @"spoon", @"sandwich", @"salad", @"girlfriend", @"housekeeper",
                  @"porch", @"battery", @"yearbook", @"outhouse", @"stocking",
                  @"hairpiece", @"timepiece", @"beehive", @"antique", @"dromedary", @"bassoon", @"artillery", @"gaslamp", @"carriage", @"encore",
                  @"teakettle", @"saucepan", @"mast", @"boutique", @"saloon", @"dirigible", @"contraption", @"tantrum", @"contraceptive", @"snowplow",
                  @"chainsaw", @"parachute", @"greenhouse", @"beanie", @"slingshot", @"sledgehammer", @"anvil", @"petticoat", @"jewelry", @"tornado",
                  @"boulder", @"castle", @"lighthouse", @"school", @"college", @"treehouse", @"quarry", @"bunker", @"tenement", @"mansion",
                  @"attic", @"compound", @"suite", @"campus", @"airplane", @"riverbed", @"hillside", @"amphitheater", @"library", @"street",
                  @"route", @"beach", @"reef", @"moon", @"planetoid", @"mall", @"forest", @"skyline", @"crypt", @"labyrinth",
                  nil] retain];
    };
    return list2;
}


+(NSString *)generateRandomNameLooselyBasedOnCurrentTime
{
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:(NSSecondCalendarUnit | NSMinuteCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:today];
    int day = [dateComponents day];
    int second = [dateComponents second];
    int minute = [dateComponents minute];
    int hour = [dateComponents hour];
    int month = [dateComponents month];

    // TODO: this is so ghetto, should have a RandomTable(size) class that handles this better.
    //       it would be cool if this was actually deterministic though to give it flavor.
    int col0key = (month * 30 + day) * 6529;
    int col1key = second * 4567;
    int col2key = (hour * 60 + minute * second) * 5189;
    
    int col0Index = col0key % [[RandomNameGenerator getCol0List] count];
    int col1Index = col1key % [[RandomNameGenerator getCol1List] count];
    int col2Index = col2key % [[RandomNameGenerator getCol2List] count];
    NSString *val0 = [[RandomNameGenerator getCol0List] objectAtIndex:col0Index];
    NSString *val1 = [[RandomNameGenerator getCol1List] objectAtIndex:col1Index];
    NSString *val2 = [[RandomNameGenerator getCol2List] objectAtIndex:col2Index];
    return [NSString stringWithFormat:@"%@'s %@ %@", val0, val1, val2];
}

@end
