//
//  ViewController.swift
//  LifeBoard
//
//  Created by Shaun Anderson on 12/04/2017.
//  Copyright © 2017 Shaun Anderson. All rights reserved.
//

import UIKit
import CoreData

class MainController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    //Mark: Variables
    //Lists of the different objects that are on the board
    var noteList = [note]()
    var imageList = [image]()
    var drawList = [drawing]()
    
    var lastLocation:CGPoint = CGPoint(0,0)
    
    
    var menuOpen = false
    var boardMenuOpen = false
    
    //References to the menus
    var controlview = UIView()
    var boardMenu = UIView()
    
    var board = UIView()
    var currentBoardName = "My Slate"
    
    var newImage = UIImageView()
    var selectedImage = UIImage()
    var selectedImageView = UIImageView()
    
    
    //Mark: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create Board
        let newboard = boardView(frame: CGRect(self.view.center.x - 500, self.view.center.y - 400,1000,700))
        newboard.vc = self
        newboard.backgroundColor = UIColor.lightGray
        newboard.autoresizesSubviews = true
        board = newboard
        board.center = self.view.center
        self.view.addSubview(board)
        
        //Create Add Menu
        let newControl = controlView(frame: CGRect(self.view.frame.width, 0,64,1000))
        newControl.vc = self
        newControl.autoresizingMask = [ .flexibleLeftMargin,.flexibleBottomMargin]
        newControl.autoresizesSubviews = true
        controlview = newControl
        self.view.addSubview(controlview)
        controlview.layer.zPosition = CGFloat.greatestFiniteMagnitude
        
        //Create Add Menu Button
        let addMenuButton = UIButton(frame: CGRect(self.view.frame.width - 100,50,64,64))
        addMenuButton.backgroundColor = UIColor.blue
        addMenuButton.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        addMenuButton.addTarget(self, action: #selector(self.OpenAddMenu), for: .touchUpInside)
        self.view.addSubview(addMenuButton)
        
        //Create Menu Button
        let menuButton = UIButton(frame: CGRect(10,50,52,52))
        menuButton.backgroundColor = UIColor.black
        menuButton.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        menuButton.addTarget(self, action: #selector(self.OpenBoardMenu), for: .touchUpInside)
        self.view.addSubview(menuButton)
        
        //Create Menu
        let newBoardMenu = BoardMenu(frame: CGRect(-64, 0,64,1000))
        newBoardMenu.vc = self
        newBoardMenu.autoresizingMask = [ .flexibleLeftMargin,.flexibleBottomMargin]
        newBoardMenu.autoresizesSubviews = true
        boardMenu = newBoardMenu
        self.view.addSubview(boardMenu)
        boardMenu.layer.zPosition = CGFloat.greatestFiniteMagnitude
        
        //Load all objects onto the board
        LoadNote()
        LoadImage()
    }
    
    func OpenAddMenu()
    {
        menuOpen = !menuOpen
        if(menuOpen)
        {
           UIView.animate(withDuration: 0.25, animations: {self.controlview.frame = CGRect(self.view.frame.width - 100,0,64,1000)}, completion: nil)
        }
        else
        {
            UIView.animate(withDuration: 0.25, animations: {self.controlview.frame = CGRect(self.view.frame.width,0,64,1000)}, completion: nil)
        }
    }
    
    func OpenBoardMenu()
    {
        boardMenuOpen = !boardMenuOpen
        if(boardMenuOpen)
        {
            UIView.animate(withDuration: 0.25, animations: {self.boardMenu.frame = CGRect(10,0,64,1000)}, completion: nil)
        }
        else
        {
            UIView.animate(withDuration: 0.25, animations: {self.boardMenu.frame = CGRect(-64,0,64,1000)}, completion: nil)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Will check through current data to ensure you do not create a board with the same name
    func CreateBoard(name: String)
    {
        guard let AppDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
        let managedContext = AppDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Board")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do{
            let data = try managedContext.fetch(fetchRequest)
            print(data.count)
            if(data.count == 0)
            {
                let entity = NSEntityDescription.entity(forEntityName: "Board", in: managedContext)
                let slate = NSManagedObject(entity: entity!, insertInto: managedContext)
                
                slate.setValue(name, forKey: "name")
                slate.setValue(0, forKey: "numNotes")
                
                do{
                    try managedContext.save()
                } catch _ as NSError
                {
                    print("Error saving")
                }
                print("CREATED SLATE NAMED: \(name)")
            }
            else
            {
                print("Slate already exists")
            }
        } catch _ as NSError
        {
            print("ISSUE LOADING")
        }
    }
    
    func SaveImage(image: UIImage, position: String, width: Double, height: Double)
    {
        print("SAVING: IMAGE")
        guard let AppDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
        
        let managedContext = AppDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Image", in: managedContext)
        let note = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        let imageData = UIImagePNGRepresentation(image);
        note.setValue(position, forKey: "position")
        note.setValue(imageData, forKey: "imageData")
        note.setValue(imageList.count, forKey: "id")
        do{ try managedContext.save() } catch _ as NSError { print("Error saving") }
    }
    
    
    func save(name: String, backColor: String, text: String)
    {
        print("SAVING: \(name)")
        guard let AppDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
        
        let managedContext = AppDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Note", in: managedContext)
        let note = NSManagedObject(entity: entity!, insertInto: managedContext)
        note.setValue(currentBoardName, forKey: "boardName")
        note.setValue(name, forKey: "position")
        note.setValue(noteList.count, forKey: "id")
        note.setValue(backColor, forKey: "color")
        note.setValue(text, forKey: "text")
        do{ try managedContext.save() } catch _ as NSError { print("Error saving") }
    }
    
    func LoadNote()
    {
        guard  let AppDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let managedContext = AppDelegate.persistentContainer.viewContext
        
        let noteFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        noteFetchRequest.predicate = NSPredicate(format: "boardName == %@", (currentBoardName))
        
        do{
            let data = try managedContext.fetch(noteFetchRequest)
            print(data.count)
            if(data.count > 0)
            {
                for datas in data
                {
                    //Get data
                    let location = CGPointFromString(datas.value(forKey: "position") as! String)
                    
                    //Create Notes From Data
                    let newView = note(frame: CGRect(location.x, location.y,100,100))
                    newView.vc = self
                    
                    newView.thisID = datas.value(forKey: "id") as! Int64
                    newView.backgroundColor = UIColor(hex: datas.value(forKey: "color") as! String)
                    
                    board.addSubview(newView)
                    noteList.append(newView)
                    print("LOADED: \(newView.thisID) at pos: \(location) from \(currentBoardName)")
                }
            }
        } catch _ as NSError
        {
            print("ISSUE LOADING")
        }
    }
    
    func LoadImage()
    {
        guard  let AppDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let managedContext = AppDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Image")
        
        do{
            let data = try managedContext.fetch(fetchRequest)
            print(data.count)
            if(data.count > 0)
            {
                for datas in data
                {
                    //Get data
                    let location = CGPointFromString(datas.value(forKey: "position") as! String)
                    
                    //Create Notes From Data
                    let newView = image(frame: CGRect(location.x, location.y,200,150))
                    newView.vc = self
                    let img : UIImage = UIImage(data: datas.value(forKey: "imageData") as! Data)!
                    newView.image = img
                    newView.thisID = datas.value(forKey: "id") as! Int64
                    newView.layer.zPosition = 0
                    newView.layer.borderWidth = 2
                    newView.layer.borderColor = UIColor.white.cgColor
                    
                    board.addSubview(newView)
                    imageList.append(newView)
                    print("LOADED: IMAGE:\(newView.thisID) at pos: \(location)")
                }
            }
        } catch _ as NSError
        {
            print("ISSUE LOADING")
        }
        
        print("Images loaded (\(imageList.count))")
    }
    
    //Grabs numNotes from board data and then adds its as the notes id to ensure its always unique and makes it easy to grab the specifc note from Core Data.
    func AddNote()
    {
        guard  let AppDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let managedContext = AppDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Board")
        fetchRequest.predicate = NSPredicate(format: "name == %@", currentBoardName)
        //ADD PREDICATION FOR OTHER BOARDS
        do{
            let data = try managedContext.fetch(fetchRequest)
            if(data.count > 0)
            {
                //Get unique id from numNotes value of Board
                let noteID = data[0].value(forKey: "numNotes") as! Int
                data[0].setValue((noteID) + 1, forKey: "numNotes")
 
                let newView = note(frame: CGRect(450,300,100,100))
                newView.vc = self
                newView.layer.zPosition = 0
                newView.thisID = Int64(noteID)
                
                newView.backgroundColor = UIColor.white
                
                let color = newView.backgroundColor
                let hexColor = color?.toHexString
                
                
                //Add view as subview and to list of notes
                board.addSubview(newView)
                noteList.append(newView)
                save(name: NSStringFromCGPoint(newView.center), backColor: hexColor!, text: "")
                print("Created Note")
            }
        } catch _ as NSError
        {
            print("ISSUE LOADING")
        }
    }
    
    func AddImage()
    {
        
        guard  let AppDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        let managedContext = AppDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Board")
        fetchRequest.predicate = NSPredicate(format: "name == %@", currentBoardName)
        //ADD PREDICATION FOR OTHER BOARDS
        do{
            let data = try managedContext.fetch(fetchRequest)
            if(data.count > 0)
            {
                //Get note amount
                let imageID = data[0].value(forKey: "numImages") as! Int
                data[0].setValue((imageID) + 1, forKey: "numImages")
                
                let newView = image(frame: CGRect(450,300,200,150))
                
                newView.vc = self
                newView.layer.zPosition = 0
                newView.layer.borderWidth = 2
                newView.layer.borderColor = UIColor.white.cgColor
                newImage = newView
                imageList.append(newView)
                OpenImagePicker(delegate: self, camera: false)
                
                print("Created Image")
            }
        } catch _ as NSError
        {
            print("ISSUE LOADING")
        }
    }
    
    func AddDrawing()
    {
        let newView = drawing(frame: CGRect(450,300,200,150))
        newView.vc = self
        newView.layer.zPosition = 0
        drawList.append(newView)
        drawList.append(newView)
        newView.backgroundColor = UIColor.white
        board.addSubview(newView)
    }
    
    func OpenImagePicker(delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate, camera: Bool)
    {
        let image = UIImagePickerController()
        image.modalPresentationStyle = .overCurrentContext
        image.delegate = delegate
        
        if camera == true {
            image.sourceType = UIImagePickerControllerSourceType.camera
        }
        else {
            image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        image.allowsEditing = false
        self.present(image, animated: true, completion: nil)
    }
    
    
    //Rebuild the control parts if device is rotated
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil)
        { _ in
            
            self.board.center = self.view.center
        }
    }
 
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        
        if let foundImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            selectedImage = foundImage
            newImage.image = selectedImage
            board.addSubview(newImage)
            SaveImage(image: foundImage, position: NSStringFromCGPoint(newImage.center),width: 200, height: 150)
        }
        else
        {
            selectedImage = UIImage()
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
