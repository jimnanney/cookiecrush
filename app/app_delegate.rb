class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    # allow quicker functional tests
    return true if RUBYMOTION_ENV == 'test'
    controller = RWTViewController.alloc.init
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = controller
    @window.makeKeyAndVisible
    true
  end
end
