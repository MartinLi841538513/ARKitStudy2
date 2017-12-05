//
//  ViewController.m
//  StudyAR1
//
//  Created by marttinli on 2017/11/7.
//  Copyright © 2017年 marttinli. All rights reserved.
//

#import "ViewController.h"
//3D游戏框架
#import <SceneKit/SceneKit.h>
//ARKit框架
#import <ARKit/ARKit.h>
@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (nonatomic, strong) ARWorldTrackingConfiguration *arSessionConfiguration;
@property(nonatomic,strong)SCNNode *planeNode;
@end
@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.sceneView.session runWithConfiguration:self.arSessionConfiguration];
    self.sceneView.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.sceneView.session pause];
}

//懒加载会话追踪配置
- (ARWorldTrackingConfiguration *)arSessionConfiguration
{
    if (_arSessionConfiguration != nil) {
        return _arSessionConfiguration;
    }
    //1.创建世界追踪会话配置（使用ARWorldTrackingSessionConfiguration效果更加好），需要A9芯片支持
    ARWorldTrackingConfiguration *configuration = [[ARWorldTrackingConfiguration alloc] init];
    //2.设置追踪方向 追踪平面，用的比较多
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    _arSessionConfiguration = configuration;
    //3.自适应灯光（相机从暗到强光快速过渡效果会平缓一些）
    _arSessionConfiguration.lightEstimationEnabled = YES;
    return _arSessionConfiguration;
}


#pragma mark - ARSCNViewDelegate
/**
 Called when a new node has been mapped to the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that maps to the anchor.
 @param anchor The added anchor.
 //添加节点时候调用
 当开启平地捕捉模式之后，如果捕捉到平地，ARKit会自动添加一个平地节点node
 并且同步返回平地锚点anchor
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    NSLog(@"didAddNode");
    
    if ([anchor isMemberOfClass:[ARPlaneAnchor class]]) {
        //添加一个3D平面模型，ARKit只有捕捉能力，锚点只是一个空间位置，要想更加清楚看到这个空间，我们需要给空间添加一个平地的3D模型来渲染他
        
        /*
         1.获取捕捉到的平地锚点
         既然是平地锚点，是一个平面，按照右手坐标系，我们只需要知道anchor.center.x center.z就可以描述一个平面；center.y肯定等于0。
         重要问题：rootnode是坐标系原点，默认是在手机设备初始化位置；这个center.y是相对哪个坐标系==0 的呢
         anchor.extent描述平面的长宽
         */
        ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
        //2.创建一个3D物体模型    （系统捕捉到的平地是一个不规则大小的长方形，这里笔者将其变成一个长方形，并且是否对平地做了一个缩放效果）
        NSLog(@"捕捉到平地。 add 该回调只会调用一次的样子 planeAchor:%@",planeAnchor);
        //2.创建一个3D物体模型    （系统捕捉到的平地是一个不规则大小的长方形，这里笔者将其变成一个长方形，并且是否对平地做了一个缩放效果）
        //参数分别是长宽高和圆角
        SCNBox *plane = [SCNBox boxWithWidth:planeAnchor.extent.x*0.3 height:0 length:planeAnchor.extent.z*0.3 chamferRadius:0];
        //3.使用Material渲染3D模型（默认模型是白色的，这里笔者改成红色）
        plane.firstMaterial.diffuse.contents = [UIColor redColor];
        
        //4.创建一个基于3D物体模型的节点
        SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
        //5.设置节点的位置为捕捉到的平地的锚点的中心位置  SceneKit框架中节点的位置position是一个基于3D坐标系的矢量坐标SCNVector3Make
        planeNode.position =SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z);
        
        //这个node是什么呢？这个就是arkit识别出来的平地节点，直接返回了；那么你基于返回的anchor创建的节点add到平地节点，是基于node的相对坐标系。这就解释了上面那个坐标系问题
        [node addChildNode:planeNode];
    }
}

@end

