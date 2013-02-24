# Willdo, task manager in Vim for programmers

Willdo let's you efficiently manage tasks and dependencies using Vim.
You can filter tasks using a query language based on Ruby.

More documentation is coming later.

## Tutorial

### It's all text files

The best part about Willdo is that it's all text files. The Vim plugin
makes it easier to edit Willdo files (syntax highlight, useful
keybindings), but you're still in full control of how you want to
structure your tasks.

Let's create a new file: `vim work.wdo`

```wdo
* #1 Implement new payment gateway
  :due 2013-03-01

  See http://... for documentation.

* #2 New copy for homepage
  
  We need to mention the new features
```

This shows the general structure of an *item*:

```
* some-id short-description
  :tag1 value
  :tag2

  Free text

  :tag3
```

You decide what types of IDs and tags you want to use. Everything is
permitted and Willdo handles all tags equally. In the following examples
I'm going to be using tags like `done` , `date`, `due` and `assigned`,
but I must stress that there's nothing special about these tag names.
You can use whatever tags you like.

### Using a view

Having one big file of tasks becomes rather messy quickly. In Willdo you
use a *view file* to list and filter tasks.

Run the command `:Wview` and a new file will be shown in a split view.
Let's enter a query:

```wdov
> !done
```

Then you run the view using `:Wrun` (mapped to `<Leader>r`):

```wdov
> !done
#1 Implement new payment gateway
#2 New copy for homepage
```

You can re-order items and the order will be preserved when you run it
later. When your cursor is over an item ID, you can use `:Wjump` (mapped
to `<Enter>`) to jump to that item in your main file. 

Let's jump to the item and mark it as completed:

```wdo
* #2 New copy for homepage
  :done 2013-02-24
```

When you re-run the view, it's gone:

```wdov
> !done
#1 Implement new payment gateway
```

### Managing dependencies

Tasks very often have dependencies. You can't finish implementing the
payment gateway before you have the updated design from your designer.
Willdo does *not* support nesting; instead it has some useful features
for managing dependencies:

```wdo
* #3 Updated design for payment page
  :blocks #1

* #4 Get access to test account
  :blocks #1

* #5 Write backend code for payment gateway 
  :blocks #1

* #6 Get access to payment gateway documentation
  :blocks #5
```

`:blocks` is just a regular tag, but the view supports a special
"reverse" filtering:

```wdov
> !done && !blocked
#3 Updated design for payment page
#4 Get access to test account
#6 Get access to payment gateway documentation
```

`!blocked` allows us to filter away tasks that are blocked and we can
focus on the tasks that we can actually accomplish.

In this case we need to delegate all of these tasks. After sending some
emails around, I would tag these tasks as `:assigned <name>` and tweak
the query:

```wdov
> !done && !assigned && !blocked
```

### Using dependencies for categorizations and milestones

You can use Willdo's `blocks` to implement categories and milestones
too:

```wdo
* Project

* Project_1 First public release
  :due 2013-03-01
  :meta
  :blocks Project

* #1 Implement new payment gateway
  :blocks Project_1
```

We can then use bang (`!`) to filter based on the "parent" tasks:

```wdov
Tasks left on Project
> !done && blocks!("Project") && !meta
#1 Implement new payment gateway

Tasks that are soon due
> !done && due!(5.days)
#1 Implement new payment gateway
```

Although `#1` itself isn't blocking `Project` or is due in five days,
`blocks!` and `due!` will match because the parent `Project_1` matches.

