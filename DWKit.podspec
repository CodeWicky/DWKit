Pod::Spec.new do |s|
s.name = 'DWKit'
s.version = '0.0.0.22'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = '打造一个自己用的工具集。'
s.homepage = 'https://github.com/CodeWicky/DWKit'
s.authors = { 'codeWicky' => 'codewicky@163.com' }
s.source = { :git => 'https://github.com/CodeWicky/DWKit.git', :tag => s.version.to_s }
s.requires_arc = true
s.ios.deployment_target = '8.0'
# 这里不写source_files是因为Pods认为一个库包括其source_files/resource/subSpec。如果写一次source_files则Pods认为所有文件都属于此Pods且其子Pods会计算第二遍。这样当引入此库时，会将原本放在字库文件夹中的文件存放到根目录下，导致存储结构改变。故字库中的文件，不需要再父库的source_files中出现。
# s.source_files  = 'DWKit/**/*.{h,m}'
s.frameworks = 'UIKit'

# 下面开始添加子库
# 这里开始是DWUtils的子库
s.subspec 'DWUtils' do |d|
  d.subspec 'DWAlbumManager' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWAlbumManager/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWAlbumManager/**/DWAlbumManager.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWCameraManager' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWCameraManager/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWCameraManager/**/{DWCameraManager,DWCameraManagerView,DWCameraManagerViewController}.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWDispatcher' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWDispatcher/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWDispatcher/**/DWDispatcher.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWFileManager' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWFileManager/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWFileManager/**/DWFileManager.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWForwardingTarget' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWForwardingTarget/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWForwardingTarget/**/DWForwardingTarget.h'
    ss.frameworks = 'Foundation'
  end
  
  d.subspec 'DWLimitArray' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWLimitArray/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWLimitArray/**/DWLimitArray.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWManualOperation' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWManualOperation/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWManualOperation/**/DWManualOperation.h'
    ss.frameworks = 'UIKit'
  end

  d.subspec 'DWOperationCancelFlag' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWOperationCancelFlag/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWOperationCancelFlag/**/DWOperationCancelFlag.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWTaskQueue' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWTaskQueue/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWLimitArray/**/DWTaskQueue.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWTransaction' do |ss|
    ss.source_files = 'DWKit/DWUtils/DWTransaction/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWUtils/DWTransaction/**/DWTransaction.h'
    ss.frameworks = 'UIKit'
  end
end

# 这里开始是DWCategory的子库
s.subspec 'DWCategory' do |d|
  d.subspec 'DWArrayUtils' do |ss|
    ss.source_files = 'DWKit/DWCategory/DWArrayUtils/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWCategory/DWArrayUtils/**/NSArray+DWArrayUtils.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWDateUtils' do |ss|
    ss.source_files = 'DWKit/DWCategory/DWDateUtils/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWCategory/DWDateUtils/**/NSDate+DWDateUtils.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWDeviceUtils' do |ss|
    ss.source_files = 'DWKit/DWCategory/DWDeviceUtils/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWCategory/DWDeviceUtils/**/UIDevice+DWDeviceUtils.h'
    ss.frameworks = 'UIKit' , 'Security'
  end
  
  d.subspec 'DWObjectUtils' do |ss|
    ss.source_files = 'DWKit/DWCategory/DWObjectUtils/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWCategory/DWObjectUtils/**/NSObject+DWObjectUtils.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWStringUtils' do |ss|
    ss.source_files = 'DWKit/DWCategory/DWStringUtils/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWCategory/DWStringUtils/**/NSString+DWStringUtils.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWThreadUtils' do |ss|
    ss.source_files = 'DWKit/DWCategory/DWThreadUtils/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWCategory/DWThreadUtils/**/NSThread+DWThreadUtils.h'
    ss.frameworks = 'UIKit'
  end
end

# 这里开始是DWComponent的子库
s.subspec 'DWComponent' do |d|
  d.subspec 'DWFixAdjustCollectionView' do |ss|
    ss.source_files = 'DWKit/DWComponent/DWFixAdjustCollectionView/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWComponent/DWFixAdjustCollectionView/**/DWFixAdjustCollectionView.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWGradientView' do |ss|
    ss.source_files = 'DWKit/DWComponent/DWGradientView/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWComponent/DWGradientView/**/DWGradientView.h'
    ss.frameworks = 'UIKit'
  end
  
  d.subspec 'DWLabel' do |ss|
    ss.source_files = 'DWKit/DWComponent/DWLabel/**/*.{h,m}'
    ss.public_header_files = 'DWKit/DWComponent/DWLabel/**/DWLabel.h'
    ss.frameworks = 'UIKit'
  end
end

end
