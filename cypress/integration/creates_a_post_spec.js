describe('Creates a post', () => {
  it('works', () => {
    cy.visit('localhost:3000/posts/new')
    cy.get('#post_title').invoke('width').should('be.gt', 0)

    cy.get('#post_title').type('my post')

    // cy.get('#post_body').invoke('width').should('be.gt', 0)
    cy.get('#post_body').type('the body', {force: true})

    // cy.get('#post_category_id').invoke('width').should('be.gt', 0)
    cy.get('#post_category_id').select('ruby', {force: true})

    // cy.get('input[type="submit"]').invoke('width').should('be.gt', 0)

    cy.get('input[type="submit"]').click()

    cy.get('.category').contains('Category: ruby')
  })
})
