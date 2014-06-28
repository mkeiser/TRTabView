TRTabView
=========

**What it is**

`TRTabView` is a tab view as seen in Mobile Safari for iPad, using the familiar delegate/data source design pattern known from `UITableView`.

![screencast](http://tristan-software.com/TRTabView/TRtabAnim.gif)

**Overview**

`TRTabView` uses a delegate design pattern that is inspired by the `UITableView` delegate and data source methods.

Tab reordering, overflow behavior, the minimum/maximum number of tabs, the minimum/maximum tab widths and much more are easy configurable by implementing the corresponding delegate calls.

For most settings there is a reasonable default already provided.

Display orientation changes are supported out of the box.

See https://github.com/mkeiser/TRTabView for an example project.

**View setup**

The actual `TRTabView` is only the area that contains the tabs. It can be added freely to any superview. It does not manage the actual content you want to display for each tab. So what actually happens when a tab is selected is entirely up to you.

The project contains the `TRTabViewToolbar` class (a subclass of UIToolbar) which should be placed above the tab view to form its upper area (the "roots" of the tabs). However, apart from drawing a background that matches the tab bar, it does not have any special functionality. One could also use a UINavigationBar subclass or a custom view instead.

![View Layout](http://tristan-software.com/TRTabView/TRTabViewViewLayout.jpg)

**How to use**

Create a TRTabView and assign a delegate to it that conforms to the `TRTabViewDelegate` protocol.

A minimal delegate implementation looks something like this:

	/* Assume "self.model" holds an array of strings that represent the tab titles. */

	- (NSUInteger)numberOfTabsInTabView:(TRTabView *)tabView {

		return [self.model count];
	}

	- (TRTab *)tabView:(TRTabView *)tabView tabForIndex:(NSUInteger)index {

		TRTab *tab = [tabView dequeueDefaultTabForIndex:index]; // Use default tab views
		tab.titleLabel.text = [self.model objectAtIndex:index];

		return tab;
	}

	/* Return the title to use in the overflow popover. */

	- (NSString *)overflowTitleForIndex:(NSUInteger)index {

		return [self.model objectAtIndex:index];
	}

	- (void)tabView:(TRTabView *)tabView didSelectTabAtIndex:(NSUInteger)index {

		id modelObject = self.model[index];

		/* Display content view for model object */
	}


When you show the add button (`tabView.showAddButton = YES`), you should implement a method to handle tab additions:

	- (void)tabViewCommitTabAddition:(TRTabView *)tabView {

		id modelObject = new model object...
		NSUInteger index = new model object index...
		[self.model insertObject:modelObject atIndex:index];

		[tabView addTabAtIndex:index animated:YES];
	}

If you enable tab deletion (`tabView.deleteButtonMode != TRTabViewButtonModeNever`), you need to handle tab deletion:

	- (void)tabView:(TRTabView *)tabView commitTabDeletionAtIndex:(NSUInteger)index {

		[self.model removeObjectAtIndex:index];

		[self.tabView deleteTabAtIndex:index animated:YES];
	}

`TRTabView` is quite flexible and offers many ways to customize its behaviour. Please check the header files for addtional methods and properties.


**License**

MIT

**Contact**

[matthias@tristan-inc.com]

[tristan-inc.com]

[github.com/mkeiser]

[matthias@tristan-inc.com]:mailto:matthias@tristan-inc.com
[tristan-inc.com]:http://tristan-inc.com
[github.com/mkeiser]:https://github.com/mkeiser