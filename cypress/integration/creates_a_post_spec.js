const context = describe

describe('Creates a post', () => {
  context('the post is valid', () => {
    it('redirects to the created post', () => {
      cy.visit('localhost:3000/posts/new')

      cy.get('#post_title').type('my post', {force: true})
      cy.get('#post_body').type('this is the post body', {force: true})
      cy.get('#post_category_id').select('ruby', {force: true})

      cy.get('input[type="submit"]').click()

      cy.get('.category').contains('Category: ruby')
    })
  })

  context('post title is not valid', () => {
    it('shows flash message with error', () => {
      cy.visit('localhost:3000/posts/new')

      cy.get('#post_title').type('aa', {force: true})
      cy.get('#post_body').type('this is the post body', {force: true})
      cy.get('#post_category_id').select('ruby', {force: true})

      cy.get('input[type="submit"]').click()

      cy.get('body').contains('Title is too short')
    })
  })
})
