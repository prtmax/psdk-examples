//
//  BaseVC.m
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "BaseVC.h"

@interface BaseVC ()

@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    if(self.navigationController.viewControllers.count > 1) {
        UIButton *navBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
        [navBtn setImage:[UIImage imageNamed:@"navBack"] forState:UIControlStateNormal];
        [navBtn addTarget:self action:@selector(popViewController) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:navBtn];
    }
   
    self.title = [self.device deviceName];
}

- (void)popViewController {
    if(self.navBackCallBack) self.navBackCallBack();
    [self.navigationController popViewControllerAnimated:YES];
}

@end
