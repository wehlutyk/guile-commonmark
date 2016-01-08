;; Copyright (C) 2015, 2016  Erik Edrosa <erik.edrosa@gmail.com>
;;
;; This file is part of guile-commonmark
;;
;; guile-commonmark is free software: you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.
;;
;; guile-commonmark is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public License
;; along with guile-commonmark.  If not, see <http://www.gnu.org/licenses/>.

(define-module (commonmark node)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-26)
  #:export (make-node
            node?
            node-type
            node-children
            node-data
            node-get-data
            node-add-data
            node-closed?
            no-children?
            make-document-node
            document-node?
            make-hrule-node
            hrule-node?
            make-paragraph-node
            paragraph-node?
            make-block-quote-node
            block-quote-node?
            make-code-block-node
            code-block-node?
            make-fenced-code-node
            fenced-code-node?
            make-list-node
            list-node?
            make-item-node
            item-node?
            make-header-node
            header-node?
            make-text-node
            join-text-nodes
            text-node?
            make-softbreak-node
            softbreak-node?
            child-closed?
            close-node
            last-child
            rest-children
            add-child-node
            replace-last-child
            print-node))

;; Node-Type is one of:
;; - 'document
;; - 'hrule
;; - 'paragraph
;; - 'block-quote
;; - 'code-block
;; - 'fenced-code
;; - 'list
;; - 'item
;; - 'header
;; - 'text
;; - 'softbreak
;; interp. The type of CommonMark block node

;; Node is (make-node Node-Type Node-Data (listof Node))
;; interp. a node to represent a CommonMark document
(define* (make-node type #:optional data (children '()))
  (cons* type (or data '((closed . #f))) children))

(define (node? node)
  (pair? node))

(define (node-type node)
  (car node))

(define (node-data node)
  (cadr node))

(define (node-children node)
  (cddr node))

(define (node-get-data node key)
  (assq-ref (node-data node) key))

(define (node-add-data node key value)
  (make-node (node-type node)
             (acons key value (node-data node))
             (node-children node)))

(define (node-closed? node)
  (node-get-data node 'closed))


;; (listof Node) -> Boolean
;; returns true if the n has no children
(define (no-children? n)
  (null? (node-children n)))

;; Node Node-Type -> Boolean
(define (node-type? n t)
  (eq? (node-type n) t))


;; Document node
;; A document node is the root of a commonmark document
(define (make-document-node)
  (make-node 'document))

;; Node -> Boolean
(define (document-node? n)
  (node-type? n 'document))

;; Hrule node
;; A hrule node represents a horizontal rule in a commonmark document
(define (make-hrule-node)
  (close-node (make-node 'hrule)))

;; Node -> Boolean
(define (hrule-node? n)
  (node-type? n 'hrule))

;; Paragraph node
;; A paragraph node represents a paragraph in a commonmark document
;; with text nodes as children
;; String -> Node
(define (make-paragraph-node text)
  (make-node 'paragraph #f (list (make-text-node text))))

;; Node -> Boolean
(define (paragraph-node? n)
  (node-type? n 'paragraph))

;; Block quote node
;; A block quote node represents a block quote in a commonmark document
;; which contains other nodes as children
;; Node -> Node
(define (make-block-quote-node node)
  (make-node 'block-quote #f (list node)))

;; Node -> Boolean
(define (block-quote-node? n)
  (node-type? n 'block-quote))

;; Code block node
;; represents a code block which contains string as children
;; String -> Node
(define (make-code-block-node line)
  (make-node 'code-block #f (list line)))

;; Node -> Boolean
(define (code-block-node? n)
  (node-type? n 'code-block))

;; Fenced code node
;; represents a fenced code block which contains a fence type
;; and info-string
;; Data -> Node
(define (make-fenced-code-node data)
  (make-node 'fenced-code data '()))

;; Node -> Boolean
(define (fenced-code-node? n)
  (node-type? n 'fenced-code))

;; List node
;; represents a list which only contains item nodes
;; Node Data -> Node 
(define (make-list-node item data)
  (make-node 'list data (list item)))

;; Node-> Boolean
(define (list-node? n)
  (node-type? n 'list))

;; Item node
;; represents a item which can only be in a list
;; Node -> Node
(define (make-item-node node padding)
  (make-node 'item `((padding . ,padding)) (if node (list node) '()) ))

;; Node -> Boolean
(define (item-node? n)
  (node-type? n 'item))


;; Level is an Integer [1-6]
;; Header node
;; represents either a atx header or setext header
;; String Level -> Node
(define (make-header-node text level)
  (make-node 'header
             `((level . ,level)
               (closed . #t))
             (list (make-text-node text)) ))

;; Node -> Boolean
(define (header-node? n)
  (node-type? n 'header))

;; Text node
;; String Boolean -> Node
(define (make-text-node text)
  (make-node 'text '((closed . #t)) (list (string-trim text))))

(define (join-text-nodes tn1 tn2)
  (make-node 'text
             '((closed . #t))
             (list (string-append (last-child tn1)
                                  "\n"
                                  (last-child tn2)))))

(define (text-node? n)
  (node-type? n 'text))

;; Softbreak node
(define (make-softbreak-node)
  (make-node 'softbreak '((closed . #t))))

(define (softbreak-node? n)
  (node-type? n 'softbreak))

(define (child-closed? n)
  (node-closed? (last-child n)))



;; Node -> Node
;; closes the node without changing any of the other properties
(define (close-node n)
  (node-add-data n 'closed #t))

(define (last-child n)
  (car (node-children n)))

(define (rest-children n)
  (cdr (node-children n)))

(define (add-child-node node child)
  (make-node (node-type node)
             (node-data node)
             (cons child (node-children node))))

(define (replace-last-child node new-child)
  (make-node (node-type node)
             (node-data node)
             (cons new-child (rest-children node))))

(define (fold-node f n)
  (cond ((not (node? n)) n)
        (else (f (make-node (node-type n)
                            (node-data n)
                            (fold (cut cons (fold-node f <>) <>)
                                  '()
                                  (node-children n)))))))

(define (print-node n)
  (define (inner n d)
    (cond ((null? n) #f)
          ((string? n)
           (display "\"")
           (display n)
           (display "\""))
          ((text-node? n)
           (add-depth d) 
           (display (node-children n))) 
          (else
           (add-depth d)
           (display (node-type n))
           (display (node-data n))
           (map (lambda (n) 
                  (newline)
                  (inner n (+ d 1))) (node-children n)))))
  (inner n 0)
  (newline))

(define (add-depth d)
  (when (> d 0)
    (display "   ")
    (add-depth (- d 1))))
