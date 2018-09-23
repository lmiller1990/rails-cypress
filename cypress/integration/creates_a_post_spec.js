describe('Creates a post', () => {
  it('works', () => {
    cy.visit('localhost:3000/posts/new')
    cy.get('#post_title').type('my post')
    cy.get('#post_body').type('the body')
    cy.get('#post_category_id').select('ruby')
    cy.get('input[type="submit"]').click()

    cy.get('.category').contains('Category: ruby')
  })
})
