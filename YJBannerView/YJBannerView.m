//
//  YJBannerView.m
//  YJBannerViewDemo
//
//  Created by YJHou on 2014/5/24.
//  Copyright © 2014年 地址:https://github.com/YJManager/YJBannerViewOC . All rights reserved.
//

#import "YJBannerView.h"
#import "YJBannerViewCell.h"
#import "UIView+YJBannerViewExt.h"
#import "TAPageControl.h"
#import <UIImageView+WebCache.h>

static NSString *const bannerViewCellId = @"YJBannerViewCell";
#define kBannerViewPageControlDotSize CGSizeMake(10, 10)

@interface YJBannerView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout; /**< 流程控制 */
@property (nonatomic, weak) UICollectionView *collectionView; /**< 主视图 */
@property (nonatomic, weak) UIControl *pageControl;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, assign) NSInteger totalItemsCount;

@property (nonatomic, strong) UIImageView *backgroundImageView; /**< 数据为空时的背景图 */

@end

@implementation YJBannerView

+ (YJBannerView *)bannerViewWithFrame:(CGRect)frame dataSource:(id<YJBannerViewDataSource>)dataSource delegate:(id<YJBannerViewDelegate>)delegate placeholderImage:(UIImage *)placeholderImage{
    YJBannerView *bannerView = [[YJBannerView alloc] initWithFrame:frame];
    bannerView.dataSource = dataSource;
    bannerView.delegate = delegate;
    bannerView.placeholderImage = placeholderImage;
    return bannerView;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initSetting];
        [self _setupMainView];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self _initSetting];
    [self _setupMainView];
}

- (void)_initSetting{
    
    self.backgroundColor = [UIColor whiteColor];
    
    _autoDuration = 2.0;
    _autoScroll = YES;
    _pageControlStyle = YJBannerViewPageControlSystem;
    _pageControlAliment = YJBannerViewPageControlAlimentCenter;
    _pageControlDotSize = kBannerViewPageControlDotSize;
    _pageControlBottomMargin = 0.0;
    _pageControlHorizontalEdgeMargin = 0.0;
    _pageControlNormalColor = [UIColor lightGrayColor];
    _pageControlHighlightColor = [UIColor whiteColor];
    _bannerImageViewContentMode = UIViewContentModeScaleToFill;
    
    _onlyDisplayText = NO;
    _titleFont = [UIFont systemFontOfSize:14.0f];
    _titleTextColor = [UIColor whiteColor];
    _titleBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    _titleHeight = 30.0f;
    _titleAlignment = NSTextAlignmentLeft;
}

- (void)_setupMainView{
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0.0f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout = flowLayout;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.pagingEnabled = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    [collectionView registerClass:[YJBannerViewCell class] forCellWithReuseIdentifier:bannerViewCellId];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.scrollsToTop = NO;
    [self addSubview:collectionView];
    _collectionView = collectionView;
}

#pragma mark - Setter && Getter
- (void)setPlaceholderImage:(UIImage *)placeholderImage{
    _placeholderImage = placeholderImage;
    
    if (!self.backgroundImageView) {
        UIImageView *bgImageView = [UIImageView new];
        bgImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self insertSubview:bgImageView belowSubview:self.collectionView];
        self.backgroundImageView = bgImageView;
    }
    self.backgroundImageView.image = placeholderImage;
}

- (void)setPageControlDotSize:(CGSize)pageControlDotSize{
    _pageControlDotSize = pageControlDotSize;
    [self _setupPageControl];
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageContol = (TAPageControl *)_pageControl;
        pageContol.dotSize = pageControlDotSize;
    }
}

- (void)setPageControlStyle:(YJBannerViewPageControlStyle)pageControlStyle{
    _pageControlStyle = pageControlStyle;
    [self _setupPageControl];
}

- (void)setPageControlNormalColor:(UIColor *)pageControlNormalColor{
    _pageControlNormalColor = pageControlNormalColor;
    if ([self.pageControl isKindOfClass:[UIPageControl class]]) {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageControlNormalColor;
    }
}

- (void)setPageControlHighlightColor:(UIColor *)pageControlHighlightColor{
    _pageControlHighlightColor = pageControlHighlightColor;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        pageControl.dotColor = pageControlHighlightColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = pageControlHighlightColor;
    }
}

- (void)setPageControlNormalImage:(UIImage *)pageControlNormalImage{
    _pageControlNormalImage = pageControlNormalImage;
    if (self.pageControlStyle != YJBannerViewPageControlAnimated) {
        self.pageControlStyle = YJBannerViewPageControlAnimated;
    }
    [self setCustomPageControlDotImage:pageControlNormalImage isCurrentPageDot:NO];
}

- (void)setPageControlHighlightImage:(UIImage *)pageControlHighlightImage{
    _pageControlHighlightImage = pageControlHighlightImage;
    
    if (self.pageControlStyle != YJBannerViewPageControlAnimated) {
        self.pageControlStyle = YJBannerViewPageControlAnimated;
    }
    [self setCustomPageControlDotImage:pageControlHighlightImage isCurrentPageDot:YES];
}

- (void)setCustomPageControlDotImage:(UIImage *)image isCurrentPageDot:(BOOL)isCurrentPageDot{
    if (!image || !self.pageControl) return;
    
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        if (isCurrentPageDot) {
            pageControl.currentDotImage = image;
        } else {
            pageControl.dotImage = image;
        }
    }
}

- (void)setAutoScroll:(BOOL)autoScroll{
    _autoScroll = autoScroll;
    
    [self invalidateTimer];
    if (_autoScroll) {
        [self _setupTimer];
    }
}

- (void)setScrollDirection:(YJBannerViewDirection)scrollDirection{
    _scrollDirection = scrollDirection;
    
    if (scrollDirection == YJBannerViewDirectionLeft || scrollDirection == YJBannerViewDirectionRight) {
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }else if (scrollDirection == YJBannerViewDirectionTop || scrollDirection == YJBannerViewDirectionBottom){
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
}

- (void)setAutoDuration:(CGFloat)autoDuration{
    _autoDuration = autoDuration;
    [self setAutoScroll:self.autoScroll];
}

#pragma mark - Lazy
- (void)layoutSubviews{
    [super layoutSubviews];
    
    _flowLayout.itemSize = self.frame.size;
    
    _collectionView.frame = self.bounds;
    if (_collectionView.contentOffset.x == 0 &&  _totalItemsCount) {
        int targetIndex = 0;
        targetIndex = _totalItemsCount * 0.5;
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
    
    CGSize size = CGSizeZero;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        if (!(self.pageControlNormalImage && self.pageControlHighlightImage && CGSizeEqualToSize(kBannerViewPageControlDotSize, self.pageControlDotSize))) {
            pageControl.dotSize = self.pageControlDotSize;
        }
        size = [pageControl sizeForNumberOfPages:[self _imageDataSources].count];
    } else {
        size = CGSizeMake([self _imageDataSources].count * self.pageControlDotSize.width * 1.5, self.pageControlDotSize.height);
    }
    CGFloat x = (self.width_bannerView - size.width) * 0.5;
    if (self.pageControlAliment == YJBannerViewPageControlAlimentLeft) { // 靠左
        x = 10.0f;
    }else if (self.pageControlAliment == YJBannerViewPageControlAlimentCenter){ // 居中
    
    }else if (self.pageControlAliment == YJBannerViewPageControlAlimentRight){ // 靠右
        x = self.collectionView.width_bannerView - size.width - 10;
    }
    
    CGFloat y = self.collectionView.height_bannerView - size.height - 10;
    
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        [pageControl sizeToFit];
    }
    
    CGRect pageControlFrame = CGRectMake(x, y, size.width, size.height);
    pageControlFrame.origin.y -= self.pageControlBottomMargin;
    pageControlFrame.origin.x -= self.pageControlHorizontalEdgeMargin;
    self.pageControl.frame = pageControlFrame;
    if (self.pageControlStyle == YJBannerViewPageControlNone) {
        self.pageControl.hidden = YES;
    }else{
        self.pageControl.hidden = NO;
    }
    if (self.backgroundImageView) {
        self.backgroundImageView.frame = self.bounds;
    }
}

#pragma mark - 解决兼容优化问题
- (void)willMoveToSuperview:(UIView *)newSuperview{
    if (!newSuperview) { // 当父类释放 因定时器引用而无法释放的问题
        [self invalidateTimer];
    }
}

- (void)dealloc {
    // 解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

- (void)adjustBannerViewWhenViewWillAppear{
    long targetIndex = [self _currentIndex];
    if (targetIndex < _totalItemsCount) {
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _totalItemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    YJBannerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:bannerViewCellId forIndexPath:indexPath];
    long itemIndex = [self _pageControlIndexWithCurrentCellIndex:indexPath.item];
    
    NSString *imagePath = [self _imageDataSources][itemIndex];
    
    if (!self.onlyDisplayText && [imagePath isKindOfClass:[NSString class]]) {
        if ([imagePath hasPrefix:@"http"]) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:self.placeholderImage];
        } else {
            UIImage *image = [UIImage imageNamed:imagePath];
            if (!image) {
                image = [UIImage imageWithContentsOfFile:imagePath];
            }
            cell.imageView.image = image;
        }
    } else if (!self.onlyDisplayText && [imagePath isKindOfClass:[UIImage class]]) {
        cell.imageView.image = (UIImage *)imagePath;
    }
    
    if ([self _titlesDataSources].count && itemIndex < [self _titlesDataSources].count) {
        cell.title = [self _titlesDataSources][itemIndex];
    }
    
    if (!cell.hasConfigured) {
        cell.titleLabelBackgroundColor = self.titleBackgroundColor;
        cell.titleLabelHeight = self.titleHeight;
        cell.titleLabelTextAlignment = self.titleAlignment;
        cell.titleLabelTextColor = self.titleTextColor;
        cell.titleLabelTextFont = self.titleFont;
        cell.hasConfigured = YES;
        cell.imageView.contentMode = self.bannerImageViewContentMode;
        cell.clipsToBounds = YES;
        cell.onlyDisplayText = self.onlyDisplayText;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerView:didSelectItemAtIndex:)]) {
        [self.delegate bannerView:self didSelectItemAtIndex:[self _pageControlIndexWithCurrentCellIndex:indexPath.item]];
    }
    if (self.didSelectItemAtIndexBlock) {
        self.didSelectItemAtIndexBlock([self _pageControlIndexWithCurrentCellIndex:indexPath.item]);
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (![self _imageDataSources].count) return; // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self _currentIndex];
    int indexOnPageControl = [self _pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.autoScroll) {
        [self _setupTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewDidEndScrollingAnimation:self.collectionView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    if (![self _imageDataSources].count) return; // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self _currentIndex];
    int indexOnPageControl = [self _pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerView:didScroll2Index:)]) {
        [self.delegate bannerView:self didScroll2Index:indexOnPageControl];
    }
    if (self.didScroll2IndexBlock) {
        self.didScroll2IndexBlock(indexOnPageControl);
    }
}

#pragma mark - Supporting
/** 安装PageControl */
- (void)_setupPageControl{
    
    if (_pageControl) [_pageControl removeFromSuperview];
    
    if ([self _imageDataSources].count == 0 || self.onlyDisplayText) {return;}
    
    if ([self _imageDataSources].count == 1) {return;}
    
    int indexOnPageControl = [self _pageControlIndexWithCurrentCellIndex:[self _currentIndex]];
    
    switch (self.pageControlStyle) {
        case YJBannerViewPageControlNone:{
        
            break;
        }
        case YJBannerViewPageControlSystem:{
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            pageControl.numberOfPages = [self _imageDataSources].count;
            pageControl.currentPageIndicatorTintColor = self.pageControlHighlightColor;
            pageControl.pageIndicatorTintColor = self.pageControlNormalColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
            break;
        }
        case YJBannerViewPageControlAnimated:{
            TAPageControl *pageControl = [[TAPageControl alloc] init];
            pageControl.numberOfPages = [self _imageDataSources].count;
            pageControl.dotColor = self.pageControlHighlightColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
            break;
        }
        case YJBannerViewPageControlCustom:{
        
        }
        default:
            break;
    }

    if (self.pageControlNormalImage) {
        self.pageControlNormalImage = self.pageControlNormalImage;
    }
    
    if (self.pageControlHighlightImage) {
        self.pageControlHighlightImage = self.pageControlHighlightImage;
    }
}

- (void)_setupTimer{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.autoDuration target:self selector:@selector(automaticScrollAction) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

/** 停止定时器 */
- (void)invalidateTimer{
    [_timer invalidate];
    _timer = nil;
}

- (void)automaticScrollAction{
    if (0 == _totalItemsCount) return;
    int currentIndex = [self _currentIndex];
    int targetIndex = currentIndex + 1;
    [self _scrollToIndex:targetIndex];
}

- (void)_scrollToIndex:(int)targetIndex{
    if (targetIndex >= _totalItemsCount) {
        targetIndex = _totalItemsCount * 0.5;
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        return;
    }
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

/** 当前的页数 */
- (int)_currentIndex{
    
    if (_collectionView.width_bannerView == 0 || _collectionView.height_bannerView == 0) {return 0.0f;}
    int index = 0;
    if (_flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        index = (_collectionView.contentOffset.x + _flowLayout.itemSize.width * 0.5) / _flowLayout.itemSize.width;
    } else {
        index = (_collectionView.contentOffset.y + _flowLayout.itemSize.height * 0.5) / _flowLayout.itemSize.height;
    }
    return MAX(0, index);
}

- (int)_pageControlIndexWithCurrentCellIndex:(NSInteger)index{
    return (int)index % [self _imageDataSources].count;
}

/** 显示图片的数组 */
- (NSArray *)_imageDataSources{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(bannerViewImages:)]) {
        NSArray *images = [self.dataSource bannerViewImages:self];
        if (self.onlyDisplayText) {
            NSMutableArray *temp = [NSMutableArray new];
            for (int i = 0; i < [self _titlesDataSources].count; i++) {
                [temp addObject:@""];
            }
            return temp;
        }else{
            return images;
        }
    }
    return @[];
}

/** 显示的标题 */
- (NSArray *)_titlesDataSources{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(bannerViewTitles:)]) {
        NSArray *titles = [self.dataSource bannerViewTitles:self];
        return titles;
    }
    return @[];
}

#pragma mark - 刷新View
- (void)reloadView{
    
    [self invalidateTimer];
    
    _totalItemsCount = [self _imageDataSources].count * 1000;
    
    if ([self _imageDataSources].count != 1) {
        self.collectionView.scrollEnabled = YES;
        [self setAutoScroll:self.autoScroll];
    } else {
        self.collectionView.scrollEnabled = NO;
    }
    
    [self _setupPageControl];
    [self.collectionView reloadData];
}

@end