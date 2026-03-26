//
//  BaseVC.m
//  AYPrinterDemo
//
//  Created by aiyin on 2023/9/18.
//

#import "BaseVC.h"

@interface BaseVC ()

@end

@implementation BaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bleHelper = [AYBleHelper shareInstance];
    [self applyLocalization];
}

- (void)applyLocalization {
    self.navigationItem.title = [self localizedText:self.navigationItem.title];
    self.navigationItem.leftBarButtonItem.title = [self localizedText:self.navigationItem.leftBarButtonItem.title];
    self.navigationItem.rightBarButtonItem.title = [self localizedText:self.navigationItem.rightBarButtonItem.title];
    [self localizeView:self.view];
}

- (NSString *)localizedText:(NSString *)text {
    if (text.length == 0) {
        return text;
    }
    return AYLocalizedString(text);
}

- (void)localizeView:(UIView *)view {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        label.text = [self localizedText:label.text];
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        UIButtonConfiguration *configuration = button.configuration;
        NSString *title = button.currentTitle;
        if (title.length == 0 && configuration.title.length > 0) {
            title = configuration.title;
        }
        if (title.length == 0 && configuration.attributedTitle.length > 0) {
            title = configuration.attributedTitle.string;
        }
        NSString *localizedTitle = [self localizedText:title];
        if (localizedTitle.length > 0) {
            [button setTitle:localizedTitle forState:UIControlStateNormal];
            if (configuration) {
                configuration.title = localizedTitle;
                if (configuration.attributedTitle.length > 0) {
                    NSDictionary *attributes = [configuration.attributedTitle attributesAtIndex:0 effectiveRange:nil];
                    configuration.attributedTitle = [[NSAttributedString alloc] initWithString:localizedTitle attributes:attributes];
                }
                button.configuration = configuration;
            }
        }
    } else if ([view isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)view;
        textField.placeholder = [self localizedText:textField.placeholder];
    } else if ([view isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)view;
        for (NSInteger index = 0; index < segmentedControl.numberOfSegments; index++) {
            NSString *title = [segmentedControl titleForSegmentAtIndex:index];
            [segmentedControl setTitle:[self localizedText:title] forSegmentAtIndex:index];
        }
    } else if ([view isKindOfClass:[UISearchBar class]]) {
        UISearchBar *searchBar = (UISearchBar *)view;
        searchBar.placeholder = [self localizedText:searchBar.placeholder];
    }

    for (UIView *subview in view.subviews) {
        [self localizeView:subview];
    }
}

@end
