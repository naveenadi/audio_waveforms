import AVFoundation
import Accelerate

public class AudioRecorder: NSObject, AVAudioRecorderDelegate{
    var audioRecorder: AVAudioRecorder?
    var path: String?
    var hasPermission: Bool = false
    public var meteringLevels: [Float]?
    
    public func startRecording(_ result: @escaping FlutterResult,_ path: String?,_ encoder : Int?,_ sampleRate : Int?,_ fileNameFormat: String){
        let settings = [
            AVFormatIDKey: getEncoder(encoder ?? 0),
            AVSampleRateKey: sampleRate ?? 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth]
        if (path == nil) {
            let directory = NSTemporaryDirectory()
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = fileNameFormat
            let fileName = dateFormatter.string(from: date) + ".aac"
            
            self.path = NSURL.fileURL(withPathComponents: [directory, fileName])?.absoluteString
        } else {
            self.path = path
        }
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: options)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let url = URL(string: self.path!) ?? URL(fileURLWithPath: self.path!)
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            result(true)
        } catch {
            result(FlutterError(code: "", message: "Failed to start recording", details: nil))
        }
    }
    
    public func stopRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.stop()
        audioRecorder = nil
        result(path)
    }
    
    public func pauseRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.pause()
        result(false)
    }
    
    public func getDecibel(_ result: @escaping FlutterResult) {
        audioRecorder?.updateMeters()
        let amp = audioRecorder?.averagePower(forChannel: 0) ?? 0.0
        result(amp)
    }
    
    public func checkHasPermission(_ result: @escaping FlutterResult){
        switch AVAudioSession.sharedInstance().recordPermission{
            
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    self.hasPermission = allowed
                }
            }
            break
        case .denied:
            hasPermission = false
            break
        case .granted:
            hasPermission = true
            break
        @unknown default:
            hasPermission = false
            break
        }
        result(hasPermission)
    }
    public func getEncoder(_ enCoder: Int) -> Int {
        switch(enCoder) {
        case 1:
            return Int(kAudioFormatMPEG4AAC_ELD)
        case 2:
            return Int(kAudioFormatMPEG4AAC_HE)
        case 3:
            return Int(kAudioFormatOpus)
        case 4:
            return Int(kAudioFormatAMR)
        case 5:
            return Int(kAudioFormatAMR_WB)
        default:
            return Int(kAudioFormatMPEG4AAC)
        }
    }
}
