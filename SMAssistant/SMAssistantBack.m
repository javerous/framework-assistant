/*
 *  SMAssistantBack.h
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

#import "SMAssistantBack.h"


NS_ASSUME_NONNULL_BEGIN


/*
** SMAssistantBack
*/
#pragma mark - SMAssistantBack

@implementation SMAssistantBack


/*
** SMAssistantBack - Draw
*/
#pragma mark - SMAssistantBack - Draw

- (void)drawRect:(NSRect)dirtyRect
{	
    NSRect			r = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
	NSBezierPath	*frm = [NSBezierPath bezierPathWithRect:r];
	
	// Set the back color
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.555555555555555f] set];
	[frm fill];
	
	// Set the rect color
	CGFloat gray = 0.13f;
	
	[[NSColor colorWithCalibratedRed:gray green:gray blue:gray alpha:1.0] set];
	[frm stroke];
}

@end


NS_ASSUME_NONNULL_END
