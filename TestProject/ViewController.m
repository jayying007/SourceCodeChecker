//
//  ViewController.m
//  TestProject
//
//  Created by janezhuang on 2023/11/4.
//

#import "ViewController.h"
#import "Person.h"

@interface ViewController ()

@property (nonatomic) Person *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.person = [[Person alloc] init];
    [_person test2:self];
}

- (void)test1 {
    
}

@end
