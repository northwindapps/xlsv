import GoogleSignIn

class GoogleSiginInController: UIViewController {
    let googleSignInButton = UIButton()
    var window: UIWindow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signIn(sender: Any) {
      GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
        guard error == nil else { return }

        // If sign in succeeded, display the app's main content View.
          // Show the app's signed-in state.
            print("sign in")
          self.window = UIWindow(frame: UIScreen.main.bounds)
          let storyboard = UIStoryboard(name: "Main", bundle: nil)
          let initialViewController = storyboard.instantiateViewController(withIdentifier: "StartLine")
            
          self.window?.rootViewController = initialViewController
          self.window?.frame = self.window!.bounds
          self.window?.makeKeyAndVisible()
      }
    }
}
