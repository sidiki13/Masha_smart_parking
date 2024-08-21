const express = require('express');
const stripe = require('stripe')('sk_test_your_secret_key'); // Replace with your actual secret key
const app = express();
app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in cents (e.g., $10.00 is 1000 cents)
      currency: currency,
      payment_method_types: ['card'],
    });

    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    res.status(500).send({ error: err.message });
  }
});

app.listen(4242, () => console.log('Server running on port 4242'));
