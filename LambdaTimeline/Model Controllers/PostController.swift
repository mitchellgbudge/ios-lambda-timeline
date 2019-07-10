//
//  PostController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class PostController {
    
    func createPost(with title: String,
                    ofType mediaType: MediaType,
                    mediaData: Data,
                    ratio: CGFloat? = nil,
                    completion: @escaping (Bool) -> Void = { _ in }) {
        
        guard let currentUser = Auth.auth().currentUser,
            let author = Author(user: currentUser) else { return }
        
        let mediaID = UUID().uuidString
        
        let mediaRef = storageRef.child(mediaType.rawValue).child(mediaID)
        
        store(data: mediaData, at: mediaRef) { (mediaURL) in
            
            guard let mediaURL = mediaURL else { completion(false); return }
            
            let post = Post(title: title, mediaURL: mediaURL, mediaType: mediaType, ratio: ratio, author: author)
            
            self.postsRef.childByAutoId().setValue(post.dictionaryRepresentation) { (error, ref) in
                if let error = error {
                    NSLog("Error posting image post: \(error)")
                    completion(false)
                }
                
                completion(true)
            }
        }
    }
    
    func addComment(with text: String, to post: inout Post) {
        
        guard let currentUser = Auth.auth().currentUser,
            let author = Author(user: currentUser) else { return }
        
        let comment = Comment(text: text, author: author)
        post.comments.append(comment)
        
        savePostToFirebase(post)
    }
    
    func addComment(with audioData: Data, to post: Post, completion: @escaping () -> Void) {
        guard let currentUser = Auth.auth().currentUser,
            let author = Author(user: currentUser) else { completion(); return }
        
        
        let ref = storageRef.child("audioComment").child(UUID().uuidString)
        
        store(data: audioData, at: ref) { (url) in
            let comment = Comment(author: author, audioURL: url)
            
            post.comments.append(comment)
            
            self.savePostToFirebase(post, completion: { (error) in
                completion()
            })
        }
    }
    
    func observePosts(completion: @escaping (Error?) -> Void) {
        
        postsRef.observe(.value, with: { (snapshot) in
            
            guard let postDictionaries = snapshot.value as? [String: [String: Any]] else { return }
            
            var posts: [Post] = []
            
            for (key, value) in postDictionaries {
                
                guard let post = Post(dictionary: value, id: key) else { continue }
                
                posts.append(post)
            }
            
            self.posts = posts.sorted(by: { $0.timestamp > $1.timestamp })
            
            completion(nil)
            
        }) { (error) in
            NSLog("Error fetching posts: \(error)")
        }
    }
    
    func savePostToFirebase(_ post: Post, completion: @escaping (Error?) -> Void = { _ in }) {
        
        guard let postID = post.id else { completion(nil); return }
        
        let ref = postsRef.child(postID)
        
        ref.setValue(post.dictionaryRepresentation) { (error, _ ) in
            completion(error)
        }
    }
    
    private func store(data: Data, at ref: StorageReference, completion: @escaping (URL?) -> Void) {
        
        let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                NSLog("Error storing media data: \(error)")
                completion(nil)
                return
            }
            
            if metadata == nil {
                NSLog("No metadata returned from upload task.")
                completion(nil)
                return
            }
            
            ref.downloadURL(completion: { (url, error) in
                
                if let error = error {
                    NSLog("Error getting download url of media: \(error)")
                }
                
                guard let url = url else {
                    NSLog("Download url is nil. Unable to create a Media object")
                    
                    completion(nil)
                    return
                }
                completion(url)
            })
        }
        
        uploadTask.resume()
    }
    
    var posts: [Post] = []
    
    let currentUser = Auth.auth().currentUser
    let postsRef = Database.database().reference().child("posts")
    
    let storageRef = Storage.storage().reference()
}

