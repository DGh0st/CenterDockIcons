@interface SBDockIconListView : UIView
-(CGSize)defaultIconSize;
-(UIInterfaceOrientation)orientation;
-(void)resetupIcons;
-(void)resetupIconsForAnimationWithLandscapeOrientation:(BOOL)arg1;
@end

@interface SBIconView : UIView
@property (assign,nonatomic) CGFloat iconLabelAlpha;
@property (nonatomic,readonly) UIView *labelView;
@end

@interface SBIconController : UIViewController
+(id)sharedInstance;
-(SBDockIconListView *)dockListView;
@end

%hook SBDockIconListView
-(CGFloat)topIconInset {
	CGFloat result = %orig();
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(), ^{
		[self resetupIcons]; // delay it so that last icon is positioned correctly as well
	});
	return result;
}

%new
-(void)resetupIcons {
	for (SBIconView *iconView in [self subviews]) {
		BOOL isLabelHidden = (iconView.iconLabelAlpha == 0.0 || iconView.labelView.alpha == 0.0 || iconView.labelView.hidden);
		CGRect iconFrame = iconView.frame;
		CGSize defaultIconSize = [self defaultIconSize];
		iconFrame.size = defaultIconSize; // fix label layout
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape([self orientation]))
			iconFrame.origin.x = (self.frame.size.width - defaultIconSize.width) / 2; // dock on right of screen
		else if (isLabelHidden)
			iconFrame.origin.y = (self.frame.size.height - defaultIconSize.width) / 2;
		else
			iconFrame.origin.y = (self.frame.size.height - defaultIconSize.height) / 2;
		iconView.frame = iconFrame;
	}
}

%new
-(void)resetupIconsForAnimationWithLandscapeOrientation:(BOOL)arg1 {
	BOOL isCurrentlyLandscape = UIInterfaceOrientationIsLandscape([self orientation]);
	if (isCurrentlyLandscape != arg1) {
		for (SBIconView *iconView in [self subviews]) {
			BOOL isLabelHidden = (iconView.iconLabelAlpha == 0.0 || iconView.labelView.alpha == 0.0 || iconView.labelView.hidden);
			CGRect iconFrame = iconView.frame;
			CGSize defaultIconSize = [self defaultIconSize];
			iconFrame.size = defaultIconSize; // fix label layout
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
				if (arg1)
					iconFrame.origin.y = (self.frame.size.height - defaultIconSize.width) / 2; // dock on right of screen
				else if (isLabelHidden)
					iconFrame.origin.x = (self.frame.size.width - defaultIconSize.width) / 2;
				else
					iconFrame.origin.x = (self.frame.size.width - defaultIconSize.height) / 2;
			} else {
				if (isLabelHidden)
					iconFrame.origin.y = (self.frame.size.height - defaultIconSize.width) / 2;
				else
					iconFrame.origin.y = (self.frame.size.height - defaultIconSize.height) / 2;
			}
			iconView.frame = iconFrame;
		}
	}
}
%end

%hook SBIconController
-(void)viewWillTransitionToSize:(CGSize)arg1 withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)arg2 {
	SBDockIconListView *dockListView = [self dockListView];
	[arg2 animateAlongsideTransition:^(id context) {
		[dockListView resetupIconsForAnimationWithLandscapeOrientation:arg1.width > arg1.height];
	} completion:^(id context) {
		[dockListView resetupIcons];
	}];

	%orig(arg1, arg2);
}

-(void)viewDidAppear:(BOOL)arg1 {
	%orig(arg1);

	[[self dockListView] resetupIcons];
}
%end