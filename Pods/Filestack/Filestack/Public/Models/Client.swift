//
//  Client.swift
//  Filestack
//
//  Created by Ruben Nine on 10/19/17.
//  Copyright © 2017 Filestack. All rights reserved.
//

import FilestackSDK
import Foundation
import Photos
import SafariServices

private typealias CompletionHandler = (_ response: CloudResponse, _ safariError: Error?) -> Void

/// The `Client` class provides an unified API to upload files and manage cloud contents using Filestack REST APIs.
@objc(FSFilestackClient) public class Client: NSObject {
    // MARK: - Properties

    /// An API key obtained from the [Developer Portal](http://dev.filestack.com).
    @objc public let apiKey: String

    /// A `Security` object. `nil` by default.
    @objc public let security: Security?

    /// A `Config` object.
    @objc public let config: Config

    /// The Filestack SDK client used for uploads and transformations.
    @objc public var sdkClient: FilestackSDK.Client {
        return client
    }

    // MARK: - Private Properties

    private let client: FilestackSDK.Client
    private let cloudService = CloudService()

    private var lastToken: String?
    private var resumeCloudRequestNotificationObserver: NSObjectProtocol!
    private var safariAuthSession: AnyObject?

    private lazy var authCallbackURL: URL? = {
        guard let scheme = config.callbackURLScheme else { return nil }
        return URL(string: "\(scheme)://Filestack")
    }()

    // MARK: - Lifecyle Functions

    /// Default initializer.
    ///
    /// - Parameter apiKey: An API key obtained from the Developer Portal.
    /// - Parameter security: A `Security` object. `nil` by default.
    /// - Parameter config: A `Config` object. `nil` by default.
    /// - Parameter token: A token obtained from `lastToken` to use initially. This could be useful to avoid
    /// authenticating against a cloud provider assuming that the passed token has not yet expired.
    @objc public init(apiKey: String, security: Security? = nil, config: Config? = nil, token: String? = nil) {
        self.apiKey = apiKey
        self.security = security
        self.lastToken = token
        self.client = FilestackSDK.Client(apiKey: apiKey, security: security)
        self.config = config ?? Config()

        super.init()
    }

    // MARK: - Public Functions

    /// Returns an instance of a `PickerNavigationController` that will allow the user to interactively pick files from
    /// a local or cloud source and upload them to a given location.
    ///
    /// - Parameter storeOptions: An object containing the store options (e.g. location, region, container, access, etc.)
    /// If none given, S3 location with default options is assumed.
    ///
    /// - Returns: A `PickerNavigationController` that may be presented using `present(_:animated:)` from your view controller.
    @objc public func picker(storeOptions: StorageOptions = .defaults) -> PickerNavigationController {
        let storyboard = UIStoryboard(name: "Picker", bundle: Bundle(for: type(of: self)))
        let scene = PickerNavigationScene(client: self, storeOptions: storeOptions)

        return storyboard.instantiateViewController(for: scene)
    }

    /// Uploads a single `Uploadable` to a given storage location.
    ///
    /// Currently the only storage location supported is Amazon S3.
    ///
    /// - Important:
    /// If your uploadable can not return a MIME type (e.g. when passing `Data` as the uploadable), you **must** pass
    /// a custom `UploadOptions` with custom `storeOptions` initialized with a `mimeType` that better represents your
    /// uploadable, otherwise `text/plain` will be assumed.
    ///
    /// - Parameter uploadable: An item to upload conforming to `Uploadable`.
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle of the upload process
    /// as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: An `Uploader` that allows starting, cancelling and monitoring the upload.
    @discardableResult
    public func upload(using uploadable: FilestackSDK.Uploadable,
                       options: UploadOptions = .defaults,
                       queue: DispatchQueue = .main,
                       uploadProgress: ((Progress) -> Void)? = nil,
                       completionHandler: @escaping (NetworkJSONResponse) -> Void) -> Uploader {
        return client.upload(using: uploadable,
                             options: options,
                             queue: queue,
                             uploadProgress: uploadProgress,
                             completionHandler: completionHandler)
    }

    /// Uploads an array of `Uploadable` items to a given storage location.
    ///
    /// Currently the only storage location supported is Amazon S3.
    ///
    /// - Important:
    /// If your uploadable can not return a MIME type (e.g. when passing `Data` as the uploadable), you **must** pass
    /// a custom `UploadOptions` with custom `storeOptions` initialized with a `mimeType` that better represents your
    /// uploadable, otherwise `text/plain` will be assumed.
    ///
    /// - Parameter uploadables: An array of items to upload conforming to `Uploadable`. May be `nil` if you intend to
    /// add them later to the returned `Uploader`.
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle of the upload process
    /// as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: An `Uploader & DeferredAdd` that allows starting, cancelling and monitoring
    /// the upload, plus adding `Uploadables` at a later time.
    @discardableResult
    public func upload(using uploadables: [FilestackSDK.Uploadable],
                       options: UploadOptions = .defaults,
                       queue: DispatchQueue = .main,
                       uploadProgress: ((Progress) -> Void)? = nil,
                       completionHandler: @escaping ([NetworkJSONResponse]) -> Void) -> Uploader & DeferredAdd {
        return client.upload(using: uploadables,
                             options: options,
                             queue: queue,
                             uploadProgress: uploadProgress,
                             completionHandler: completionHandler)
    }

    /// Uploads a file to a given storage location picked interactively from the camera or the photo library.
    ///
    /// - Parameter viewController: The view controller that will present the picker.
    /// - Parameter sourceType: The desired source type (e.g. camera, photo library.)
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle of the upload process
    /// as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: A `Cancellable & Monitorizable` that allows cancelling and monitoring the upload.
    @discardableResult
    public func uploadFromImagePicker(viewController: UIViewController,
                                      sourceType: UIImagePickerController.SourceType,
                                      options: UploadOptions = .defaults,
                                      queue: DispatchQueue = .main,
                                      uploadProgress: ((Progress) -> Void)? = nil,
                                      completionHandler: @escaping ([NetworkJSONResponse]) -> Void) -> Cancellable & Monitorizable {
        options.startImmediately = false

        let uploader = client.upload(options: options,
                                     queue: queue,
                                     uploadProgress: uploadProgress,
                                     completionHandler: completionHandler)

        let uploadController = ImagePickerUploadController(uploader: uploader,
                                                           viewController: viewController,
                                                           sourceType: sourceType,
                                                           config: config)

        uploadController.filePickedCompletionHandler = { _ in
            // Remove completion handler, so this `ImagePickerUploadController` object can be properly deallocated.
            uploadController.filePickedCompletionHandler = nil
        }

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async { uploadController.start() }
            }
        }

        return uploader
    }

    /// Uploads a file to a given storage location picked interactively from the device's documents, iCloud Drive or
    /// other third-party cloud services.
    ///
    /// - Parameter viewController: The view controller that will present the picker.
    /// - Parameter options: A set of upload options (see `UploadOptions` for more information.)
    /// - Parameter queue: The queue on which the upload progress and completion handlers are dispatched.
    /// - Parameter uploadProgress: Sets a closure to be called periodically during the lifecycle of the upload process
    /// as data is uploaded to the server. `nil` by default.
    /// - Parameter completionHandler: Adds a handler to be called once the upload has finished.
    ///
    /// - Returns: A `Cancellable & Monitorizable` that allows cancelling and monitoring the upload.
    @discardableResult
    public func uploadFromDocumentPicker(viewController: UIViewController,
                                         options: UploadOptions = .defaults,
                                         queue: DispatchQueue = .main,
                                         uploadProgress: ((Progress) -> Void)? = nil,
                                         completionHandler: @escaping ([NetworkJSONResponse]) -> Void) -> Cancellable & Monitorizable {
        options.startImmediately = false

        let uploader = client.upload(options: options,
                                     queue: queue,
                                     uploadProgress: uploadProgress,
                                     completionHandler: completionHandler)

        let uploadController = DocumentPickerUploadController(uploader: uploader,
                                                              viewController: viewController,
                                                              config: config)

        uploadController.filePickedCompletionHandler = { _ in
            // Remove completion handler, so this `DocumentPickerUploadController` object can be properly deallocated.
            uploadController.filePickedCompletionHandler = nil
        }

        uploadController.start()

        return uploader
    }

    /// Lists the content of a cloud provider at a given path. Results are paginated (see `pageToken` below.)
    ///
    /// - Parameter provider: The cloud provider to use (e.g. Dropbox, GoogleDrive, S3)
    /// - Parameter path: The path to list (be sure to include a trailing slash "/".)
    /// - Parameter pageToken: A token obtained from a previous call to this function. This token is included in every
    /// `FolderListResponse` returned by this function in a property called `nextToken`.
    /// - Parameter queue: The queue on which the completion handler is dispatched.
    /// - Parameter completionHandler: Adds a handler to be called once the request has completed either with a success,
    /// or error response.
    ///
    /// - Returns: A `Cancellable` that allows cancelling the folder list request.
    @objc
    @discardableResult
    public func folderList(provider: CloudProvider,
                           path: String,
                           pageToken: String? = nil,
                           queue: DispatchQueue = .main,
                           completionHandler: @escaping FolderListCompletionHandler) -> Cancellable {
        guard let authCallbackURL = authCallbackURL else {
            fatalError("Please make sure your config's `callbackURLScheme` is present.")
        }

        let request = FolderListRequest(authCallbackURL: authCallbackURL,
                                        apiKey: apiKey,
                                        security: security,
                                        token: lastToken,
                                        pageToken: pageToken,
                                        provider: provider,
                                        path: path)

        perform(request: request, queue: queue) { response, safariError in
            switch (response, safariError) {
            case (let response as FolderListResponse, nil):
                completionHandler(response)
            case let (_, error):
                completionHandler(FolderListResponse(error: error))
            }
        }

        return request
    }

    /// Stores a file from a given cloud provider and path at the desired store location.
    ///
    /// - Parameter provider: The cloud provider to use (e.g. Dropbox, GoogleDrive, S3)
    /// - Parameter path: The path to a file in the cloud provider.
    /// - Parameter storeOptions: An object containing the store options (e.g. location, region, container, access, etc.)
    /// If none given, S3 location with default options is assumed.
    /// - Parameter queue: The queue on which the completion handler is dispatched.
    /// - Parameter completionHandler: Adds a handler to be called once the request has completed either with a success,
    /// or error response.
    ///
    /// - Returns: A `Cancellable` that allows cancelling the store request.
    @objc
    @discardableResult
    public func store(provider: CloudProvider,
                      path: String,
                      storeOptions: StorageOptions = .defaults,
                      queue: DispatchQueue = .main,
                      completionHandler: @escaping StoreCompletionHandler) -> Cancellable {
        let request = StoreRequest(apiKey: apiKey,
                                   security: security,
                                   token: lastToken,
                                   provider: provider,
                                   path: path,
                                   storeOptions: storeOptions)

        perform(request: request, queue: queue) { response, _ in
            guard let response = response as? StoreResponse else { return }
            completionHandler(response)
        }

        return request
    }

    /// Logs out the user from a given provider.
    ///
    /// - Parameter provider: The `CloudProvider` to logout from.
    /// - Parameter completionHandler: Adds a handler to be called once the request has completed. The response will
    /// either contain an error (on failure) or nothing at all (on success.)
    @objc public func logout(provider: CloudProvider, completionHandler: @escaping LogoutCompletionHandler) {
        guard let token = lastToken else { return }

        let logoutRequest = LogoutRequest(provider: provider, apiKey: apiKey, token: token)

        logoutRequest.perform(cloudService: cloudService, completionBlock: completionHandler)
    }

    // MARK: - Internal Functions

    func prefetch(completionBlock: @escaping PrefetchCompletionHandler) {
        let prefetchRequest = PrefetchRequest(apiKey: apiKey)

        prefetchRequest.perform(cloudService: cloudService, completionBlock: completionBlock)
    }

    // MARK: - Private Functions

    private func perform(request: CloudRequest, queue: DispatchQueue = .main, completionBlock: @escaping CompletionHandler) {
        // Perform cloud request.
        request.perform(cloudService: cloudService, queue: queue) { _, response in
            if let token = request.token {
                // Store last token
                self.lastToken = token
            }

            guard let authURL = response.authURL else {
                // Already authenticated, call completion block and return.
                completionBlock(response, nil)
                return
            }

            // Request authentication.
            let session = SFAuthenticationSession(url: authURL,
                                                  callbackURLScheme: self.config.callbackURLScheme) { url, error in
                // Remove strong reference, so object can be deallocated.
                self.safariAuthSession = nil

                if let safariError = error {
                    completionBlock(response, safariError)
                } else if let url = url, url == self.authCallbackURL {
                    self.perform(request: request, queue: queue, completionBlock: completionBlock)
                } else {
                    completionBlock(response, ClientError.authenticationFailed)
                }
            }

            // Keep a strong reference to the auth session.
            self.safariAuthSession = session

            DispatchQueue.main.async {
                session.start()
            }
        }
    }
}
