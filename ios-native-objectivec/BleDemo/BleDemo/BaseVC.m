//
//  BaseVC.m
//  BleDemo
//
//  Created by IPRT on 2022/11/22.
//

#import "BaseVC.h"

@interface BaseVC ()
@property (nonatomic , strong) UILabel *labTitle;
@property (nonatomic , strong) UIButton *btnBack;
@property (nonatomic , strong) UIView *viewTitle;
@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitleView];
    [self setContentView];
    // Do any additional setup after loading the view.
}
-(void)setTitleStr:(NSString *)titleStr{
    self.labTitle.text = titleStr;
}
-(void)isNeedBackBtn:(BOOL)isNeed{
    self.btnBack.hidden = isNeed;
}
-(void)backHandler{
    if(self.device &&self.peripheral){
        [self.device disconnect:self.peripheral];
    }
    if(self.backClick){
        self.backClick();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)setContentView{
    self.contentView  = [[UIView alloc]init];
    self.contentView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.top.mas_equalTo(self.viewTitle.mas_bottom);
    }];
   
}

-(void)setTitleView{
    [self.view addSubview:self.viewTitle];
    [self.viewTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.view);
        make.height.mas_equalTo([UIDevice p_navigationFullHeight]);
    }];
}

-(UILabel *)labTitle{
    if (!_labTitle) {
        _labTitle = [[UILabel alloc]init];
        _labTitle.font = [UIFont systemFontOfSize:16];
        _labTitle.textColor = UIColor.blackColor;
    }
    return _labTitle;
}
-(UIButton *)btnBack{
    if(!_btnBack){
        _btnBack = [[UIButton alloc]init];
        _btnBack .backgroundColor = UIColor.whiteColor;
        [_btnBack setTitle:@"返回" forState:UIControlStateNormal];
        _btnBack.titleLabel.font = [UIFont systemFontOfSize:14];
        [_btnBack addTarget:self action:@selector(backHandler) forControlEvents:UIControlEventTouchUpInside];
        [_btnBack setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }
    return _btnBack;
}
-(UIView *)viewTitle{
    if(!_viewTitle){
        _viewTitle = [[UIView alloc]init];
        _viewTitle.backgroundColor = UIColor.whiteColor;
        [_viewTitle addSubview:self.labTitle];
        [self.labTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self->_viewTitle);
            make.top.mas_equalTo(self->_viewTitle).mas_offset([UIDevice p_statusBarHeigh]);
            make.height.mas_equalTo(44);
        }];
        [_viewTitle addSubview:self.btnBack];
        [self.btnBack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.labTitle);
            make.width.height.mas_equalTo(44);
        }];
    }
    return _viewTitle;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
