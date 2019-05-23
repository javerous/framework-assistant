/*
 *  SMAssistantController.h
 *
 *  Copyright 2019 Avérous Julien-Pierre
 *
 *  This file is part of SMAssistant.
 *
 *  SMAssistant is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  SMAssistant is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with SMAssistant.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN


/*
** Types
*/
#pragma mark - Types

typedef NS_ENUM(unsigned int, SMAssistantCompletionType) {
	SMAssistantCompletionTypeCanceled,	// context = nil
	SMAssistantCompletionTypeDone		// context = last panel returned content.
};

typedef void (^SMAssistantCompletionBlock)(SMAssistantCompletionType type, id _Nullable context);



/*
** SMAssistantController
*/
#pragma mark - SMAssistantController

@interface SMAssistantController : NSObject

// -- Instance --
+ (void)startAssistantWithPanels:(NSArray *)panels completionHandler:(nullable SMAssistantCompletionBlock)callback;

@end


NS_ASSUME_NONNULL_END
