//
//  PhotoController.m
//  Y-Tiles
//
//  Created by Chris Yunker on 12/15/08.
//  Copyright 2009 Chris Yunker. All rights reserved.
//

#import "PhotoController.h"
#import "Util.h"

@implementation PhotoController

@synthesize photoLibraryButton;
@synthesize photoDefaultButton;
@synthesize selectImageView;

- (id)initWithBoard:(Board *)aBoard
{
	if (self = [super init])
	{
		board = [aBoard retain];
		
		[self setTabBarItem:[[[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"PhotoTitle", @"")
														   image:[UIImage imageNamed:@"Photo.png"]
															 tag:kTabBarPhotoTag] autorelease]];
	}
	return self;
}

- (void)dealloc
{
	DLog("dealloc");
	[photoLibraryButton release], photoLibraryButton = nil;
	[photoDefaultButton release], photoDefaultButton = nil;
	[selectImageView release], selectImageView = nil;
	[board release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
	ALog("didReceiveMemoryWarning");
	[super didReceiveMemoryWarning];
}

- (void)setView:(UIView *)aView
{
	if (aView == nil)
	{
		DLog("Setting view to nil due to low memory");
		[self setPhotoDefaultButton:nil];
		[self setPhotoLibraryButton:nil];
		[self setSelectImageView:nil];
	}
	[super setView:aView];
}

- (void)loadView
{
	[super loadView];

	if (photoLibraryButton == nil)
	{
		photoLibraryButton = [[UIBarButtonItem alloc]
							 initWithTitle:NSLocalizedString(@"PhotoLibraryButton", @"")
							 style:UIBarButtonItemStyleDone
							 target:self
							 action:@selector(photoLibraryButtonAction)];
	}
	
	if (photoDefaultButton == nil)
	{
		photoDefaultButton = [[UIBarButtonItem alloc]
							  initWithTitle:NSLocalizedString(@"PhotoDefaultButton", @"")
							  style:UIBarButtonItemStyleDone
							  target:self
							  action:@selector(photoDefaultButtonAction)];
	}
	
	if (selectImageView == nil)
	{
		selectImageView = [[UIImageView alloc] initWithImage:[board photo]];
		[[self view] addSubview:selectImageView];
	}
	
	[[self navigationItem] setLeftBarButtonItem:photoDefaultButton];
	[[self navigationItem] setRightBarButtonItem:photoLibraryButton];
}

- (void)photoDefaultButtonAction
{
	PhotoDefaultController *pdc = [[PhotoDefaultController alloc] initWithNibName:@"PhotoDefaultView" bundle:nil photoController:self];
	[self presentModalViewController:pdc animated:YES];
	[pdc release];
}

- (void)photoLibraryButtonAction
{
	// Check to make sure pictures are available
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{		
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"NoPhotos", @"")
							  message:nil
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		return;
	}
	
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	[[picker navigationBar] setBarStyle:UIBarStyleBlackOpaque];
	[picker shouldAutorotateToInterfaceOrientation:NO];
	[picker setAllowsEditing:NO];
	[picker setDelegate:self];
	[picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)selectPhoto:(UIImage *)photo type:(int)type
{
	if (type == kBoardPhotoInvalid)
	{
		// NOTE: Seems to be an iphone SDK bug when calling UIAlertView from
		// a UIImagePickerController delegate method.
		// This is an unlikely error so it's probably OK to silently error
		/*
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"InvalidPhoto", @"")
							  message:nil
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		*/
		
		return;
	}
	
	[board setPhoto:photo type:type];
	
	[selectImageView removeFromSuperview];
	[self setSelectImageView:[[[UIImageView alloc] initWithImage:[board photo]] autorelease]];
	[[self view] addSubview:selectImageView];
}

- (UIImage *)resizeImage:(UIImage *)image size:(CGSize)size
{
	UIGraphicsBeginImageContext(size);

	[image drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

	UIGraphicsEndImageContext();

	return newImage;
}


#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{	
	UIImage *image = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
	if (image == nil)
	{
		ALog("Invalid selected photo");
		[self selectPhoto:nil type:kBoardPhotoInvalid];
		[self dismissModalViewControllerAnimated:YES];
		return;
	}

	UIImage *resizedImage = [self resizeImage:image size:board.frame.size];
	
	NSString *path = [kDocumentsDir stringByAppendingPathComponent:kBoardPhoto];
	if (![UIImageJPEGRepresentation(resizedImage, 1) writeToFile:path atomically:YES])
	{
		ALog("PhotoController: Failed to write file [%@]", path);
	}
	
	[self selectPhoto:resizedImage type:kBoardPhotoType];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

//#pragma mark UIAlertViewDelegate methods
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{	
//	[alertView release];
//}

@end
