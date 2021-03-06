/*
 *  SMAssistantPanel.h
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

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


/*
** SMAssistantProxy
*/
#pragma mark - SMAssistantProxy

@protocol SMAssistantProxy <NSObject>

- (void)setNextPanelID:(nullable NSString *)panelID;
- (void)setDisableContinue:(BOOL)disabled;

@end


/*
** SMAssistantPanel
*/
#pragma mark - SMAssistantPanel

@protocol SMAssistantPanel <NSObject>

// Instance.
+ (id <SMAssistantPanel>)panelInstance;

// Panel properties.
+ (NSString *)panelIdentifier;
+ (NSString *)panelTitle;

// Content.
@property (nonatomic, readonly,) NSView *panelView;
@property (nullable, nonatomic, readonly) id panelContent;

// Context.
@property (strong, nonatomic) id <SMAssistantProxy> panelProxy;
@property (strong, nonatomic, nullable) id panelPreviousContent;

// Life.
- (void)panelDidAppear;

// Events
@optional
- (void)canceled;

@end


NS_ASSUME_NONNULL_END
