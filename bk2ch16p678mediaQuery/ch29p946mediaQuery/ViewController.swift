

import UIKit
import MediaPlayer

func imageFromContextOfSize(size:CGSize, closure:() -> ()) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    closure()
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result
}

class ViewController: UIViewController {
    
    var q : MPMediaItemCollection!
    @IBOutlet var label : UILabel!
    var timer : NSTimer!
    @IBOutlet var prog : UIProgressView!
    @IBOutlet var vv : MPVolumeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let sz = CGSizeMake(20,20)
        UIGraphicsBeginImageContextWithOptions(
            CGSizeMake(sz.height,sz.height), false, 0)
        UIColor.blackColor().setFill()
        UIBezierPath(ovalInRect:
            CGRectMake(0,0,sz.height,sz.height)).fill()
        let im1 = UIGraphicsGetImageFromCurrentImageContext()
        UIColor.redColor().setFill()
        UIBezierPath(ovalInRect:
            CGRectMake(0,0,sz.height,sz.height)).fill()
        let im2 = UIGraphicsGetImageFromCurrentImageContext()
        UIColor.orangeColor().setFill()
        UIBezierPath(ovalInRect:
            CGRectMake(0,0,sz.height,sz.height)).fill()
        let im3 = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.vv.setMinimumVolumeSliderImage(
            im1.resizableImageWithCapInsets(UIEdgeInsetsMake(9,9,9,9),
                resizingMode:.Stretch),
            forState:.Normal)
        self.vv.setMaximumVolumeSliderImage(
            im2.resizableImageWithCapInsets(UIEdgeInsetsMake(9,9,9,9),
                resizingMode:.Stretch),
            forState:.Normal)
        self.vv.volumeWarningSliderImage =
            im3.resizableImageWithCapInsets(UIEdgeInsetsMake(9,9,9,9),
                resizingMode:.Stretch)
        
        let sz2 = CGSizeMake(40,40)
        let thumb = imageFromContextOfSize(sz2) {
            UIImage(named:"SmileyRound.png").drawInRect(CGRectMake(0,0,sz2.width,sz2.height))
        }
        self.vv.setVolumeThumbImage(thumb, forState:.Normal)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"wirelessChanged:",
            name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification,
            object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"wirelessChanged2:",
            name:MPVolumeViewWirelessRouteActiveDidChangeNotification,
            object:nil)
        
    }
    
    func wirelessChanged(n:NSNotification) {
        println("wireless change \(n.userInfo)")
    }
    func wirelessChanged2(n:NSNotification) {
        println("wireless active change \(n.userInfo)")
    }
    
    @IBAction func doAllAlbumTitles (sender:AnyObject!) {
        let query = MPMediaQuery.albumsQuery()
        let result = query.collections as [MPMediaItemCollection]
        // prove we've performed the query, by logging the album titles
        for album in result {
            println(album.representativeItem.valueForProperty(MPMediaItemPropertyAlbumTitle))
        }
        return; // testing
        // cloud item values are 0 and 1, meaning false and true
        for album in result {
            for song in album.items as [MPMediaItem] {
                println("\(song.valueForProperty(MPMediaItemPropertyIsCloudItem)) \(song.valueForProperty(MPMediaItemPropertyAssetURL)) \(song.valueForProperty(MPMediaItemPropertyTitle))")
            }
        }
    }
    
    @IBAction func doBeethovenAlbumTitles (sender:AnyObject!) {
        let query = MPMediaQuery.albumsQuery()
        let hasBeethoven = MPMediaPropertyPredicate(value:"Beethoven",
            forProperty:MPMediaItemPropertyAlbumTitle,
            comparisonType:.Contains)
        query.addFilterPredicate(hasBeethoven)
        let result = query.collections as [MPMediaItemCollection]
        for album in result {
            println(album.representativeItem.valueForProperty(MPMediaItemPropertyAlbumTitle))
        }
    }
    
    @IBAction func doSonataAlbumsOnDevice (sender:AnyObject!) {
        let query = MPMediaQuery.albumsQuery()
        let hasSonata = MPMediaPropertyPredicate(value:"Sonata",
            forProperty:MPMediaItemPropertyTitle,
            comparisonType:.Contains)
        query.addFilterPredicate(hasSonata)
        
        let isPresent = MPMediaPropertyPredicate(value:false,
            forProperty:MPMediaItemPropertyIsCloudItem,
            comparisonType:.EqualTo)
        query.addFilterPredicate(isPresent)
        
        let result = query.collections as [MPMediaItemCollection]
        for album in result {
            println(album.representativeItem.valueForProperty(MPMediaItemPropertyAlbumTitle))
        }
        // and here are the songs in the first of those albums
        let album = result[0]
        for song in album.items as [MPMediaItem] {
            println(song.valueForProperty(MPMediaItemPropertyTitle))
        }
    }
    
    @IBAction func doPlayShortSongs (sender:AnyObject!) {
        let query = MPMediaQuery.songsQuery()
        // always need to filter out songs that aren't present
        let isPresent = MPMediaPropertyPredicate(value:false,
            forProperty:MPMediaItemPropertyIsCloudItem,
            comparisonType:.EqualTo)
        query.addFilterPredicate(isPresent)
        
        let shorties = (query.items as [MPMediaItem]).filter {
            let dur = $0.valueForProperty(MPMediaItemPropertyPlaybackDuration) as NSNumber
            return dur.floatValue < 30
        }
        
        if shorties.count == 0 {
            println("no songs that short!")
            return
        }
        println("got \(shorties.count) short songs")
        let queue = MPMediaItemCollection(items:shorties)
        let player = MPMusicPlayerController.applicationMusicPlayer()
        player.setQueueWithItemCollection(queue)
        player.shuffleMode = .Songs
        player.beginGeneratingPlaybackNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changed:", name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: player)
        self.q = queue // retain a pointer to the queue
        player.play()
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "timerFired:", userInfo: nil, repeats: true)
        self.timer.tolerance = 0.1
    }
    
    func changed(n:NSNotification) {
        let player = MPMusicPlayerController.applicationMusicPlayer()
        if n.object === player { // just playing safe
            let title = player.nowPlayingItem.valueForProperty(MPMediaItemPropertyTitle) as String
            let ix = player.indexOfNowPlayingItem
            if NSNotFound == ix {
                self.label.text = ""
            } else {
                self.label.text = "\(ix+1) of \(self.q.count): \(title)"
            }
        }
        self.timer?.fire() // looks better if we fire timer now
    }
    
    func timerFired(_:AnyObject) {
        let player = MPMusicPlayerController.applicationMusicPlayer()
        let item = player.nowPlayingItem
        if item == nil || player.playbackState == .Stopped {
            self.prog.hidden = true
            return
        }
        self.prog.hidden = false
        let current = player.currentPlaybackTime
        let total = (item.valueForProperty(MPMediaItemPropertyPlaybackDuration) as NSNumber).doubleValue
        self.prog.progress = Float(current / total)
    }

    
}